const express = require('express');
const router = express.Router();
const prisma = require('../config/db');
const authMiddleware = require('../middleware/authMiddleware');

router.post('/mark', authMiddleware, async (req, res) => {
  try {
    const { email, uuid, deviceHash } = req.body;

    // 1. find student
    const student = await prisma.student.findUnique({
      where: { email },
      include: { devices: true }
    });

    if (!student) {
      return res.status(404).json({ message: "Student not found" });
    }

    // 2. validate device
    const validDevice = student.devices.find(
      d => d.uuid === uuid &&
           d.deviceHash === deviceHash &&
           d.isApproved === true &&
           d.isActive === true
    );

    if (!validDevice) {
      return res.status(403).json({ message: "Invalid or unapproved device" });
    }

    // 3. find active session for student's class
    const now = new Date();

    const session = await prisma.session.findFirst({
      where: {
        department: student.department,
        semester: student.semester,
        section: student.section,
        startTime: { lte: now },
        endTime: { gte: now },
        isActive: true
      }
    });

    if (!session) {
      return res.status(400).json({ message: "No active session for your class" });
    }

    // 4. check already marked
    const existing = await prisma.attendance.findUnique({
      where: {
        studentId_sessionId: {
          studentId: student.id,
          sessionId: session.id
        }
      }
    });

    if (existing) {
      return res.json({ message: "Attendance already marked" });
    }

    // 5. mark attendance
    const attendance = await prisma.attendance.create({
      data: {
        studentId: student.id,
        sessionId: session.id,
        status: "present"
      }
    });

    res.json({ message: "Attendance marked", attendance });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// get student attendance history
router.get('/history', authMiddleware, async (req, res) => {
  try {
    const studentId = req.user.id;

    const history = await prisma.attendance.findMany({
      where: {
        studentId: studentId
      },
      include: {
        session: true
      },
      orderBy: {
        markedAt: 'desc'
      }
    });

    const formattedHistory = history.map(record => ({
      subjectName: record.session.subjectName,
      courseCode: record.session.room || "N/A",
      department: record.session.department,
      semester: record.session.semester,
      section: record.session.section,
      room: record.session.room,
      date: record.markedAt.toISOString().split('T')[0],
      startTime: record.session.startTime.toISOString(),
      endTime: record.session.endTime.toISOString(),
      status: record.status.charAt(0).toUpperCase() + record.status.slice(1)
    }));

    res.json({
      success: true,
      data: formattedHistory
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});

module.exports = router;
