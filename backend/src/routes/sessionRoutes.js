const express = require('express');
const router = express.Router();
const prisma = require('../config/db');
const authMiddleware = require('../middleware/authMiddleware');

// create session (manual for now)
router.post('/create', async (req, res) => {

  try {

    const {
      subjectName,
      department,
      semester,
      section,
      room,
      startTime,
      endTime
    } = req.body;

    // Validate required fields
    if (!subjectName || !department || !semester || !section || !startTime || !endTime) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields: subjectName, department, semester, section, startTime, endTime"
      });
    }

    const session = await prisma.session.create({
      data: {
        subjectName,
        department,
        semester: parseInt(semester),
        section,
        room,
        startTime: new Date(startTime),
        endTime: new Date(endTime)
      }
    });

    res.json({
      success: true,
      data: session
    });

  } catch (err) {

    res.status(500).json({
      success: false,
      message: err.message
    });

  }

});

// get active session (filtered by student's class)
router.get('/active', authMiddleware, async (req, res) => {
  try {
    const studentId = req.user.id;

    // Fetch student class details
    const student = await prisma.student.findUnique({
      where: { id: studentId },
      select: { department: true, semester: true, section: true }
    });

    if (!student) {
      return res.status(404).json({ success: false, message: "Student not found" });
    }

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
      return res.json({ success: true, message: "No active session for your class", data: null });
    }

    res.json({ success: true, data: session });

  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;