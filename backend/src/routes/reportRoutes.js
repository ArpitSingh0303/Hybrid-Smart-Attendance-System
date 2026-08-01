const express = require('express');
const router = express.Router();
const prisma = require('../config/db');

// STUDENT ATTENDANCE REPORT
router.get('/student/:studentId', async (req, res) => {
  try {
    const studentId = parseInt(req.params.studentId);

    // Get student details to filter sessions
    const student = await prisma.student.findUnique({
      where: { id: studentId },
      select: { department: true, semester: true, section: true }
    });

    if (!student) {
      return res.status(404).json({ success: false, message: "Student not found" });
    }

    // total sessions for this student's class
    const totalSessions = await prisma.session.count({
      where: {
        department: student.department,
        semester: student.semester,
        section: student.section
      }
    });

    // attended sessions
    const attended = await prisma.attendance.count({
      where: {
        studentId
      }
    });

    // percentage
    const percentage =
      totalSessions === 0
        ? 0
        : ((attended / totalSessions) * 100).toFixed(2);

    // low attendance check
    const lowAttendance = percentage < 75;

    res.json({
      success: true,
      data: {
        studentId,
        totalSessions,
        attended,
        percentage,
        lowAttendance
      }
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});

// =========================
// LOW ATTENDANCE STUDENTS
// =========================
router.get('/low-attendance', async (req, res) => {
  try {
    const students = await prisma.student.findMany({
      include: {
        _count: {
          select: { attendance: true }
        }
      }
    });

    const report = await Promise.all(students.map(async (student) => {
      const attended = student._count.attendance;

      // Get total sessions applicable to this student
      const totalSessions = await prisma.session.count({
        where: {
          department: student.department,
          semester: student.semester,
          section: student.section
        }
      });

      const percentage =
        totalSessions === 0
          ? 0
          : ((attended / totalSessions) * 100);

      return {
        id: student.id,
        name: student.name,
        rollNo: student.rollNo,
        email: student.email,
        percentage: percentage.toFixed(2),
        lowAttendance: percentage < 75
      };
    }));

    // only low attendance students
    const filtered = report.filter(
      s => s.lowAttendance
    );

    if (filtered.length === 0) {
      return res.json({
        success: true,
        message: "No students with low attendance",
        totalStudents: 0,
        data: []
      });
    }

    res.json({
      success: true,
      totalStudents: filtered.length,
      data: filtered
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});

module.exports = router;