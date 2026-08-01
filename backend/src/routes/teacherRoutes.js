const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const router = express.Router();

const prisma = require('../config/db');
// IMPROVEMENT: Moved middleware import to the top for better structure
const teacherAuthMiddleware = require('../middleware/teacherAuthMiddleware');

// ======================
// TEACHER SIGNUP
// ======================

router.post('/signup', async (req, res) => {
  try {
    const {
      name,
      email,
      password,
      department
    } = req.body;

    const existing = await prisma.teacher.findUnique({
      where: { email }
    });

    if (existing) {
      return res.status(400).json({
        success: false,
        message: "Teacher already exists"
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const teacher = await prisma.teacher.create({
      data: {
        name,
        email,
        password: hashedPassword,
        department
      }
    });

    delete teacher.password;

    res.status(201).json({
      success: true,
      message: "Teacher registered successfully",
      data: teacher
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});

// ======================
// TEACHER LOGIN
// ======================

router.post('/login', async (req, res) => {
  try {
    const {
      email,
      password
    } = req.body;

    const teacher = await prisma.teacher.findUnique({
      where: { email }
    });
    
    console.log("Teacher Found:", teacher);

    if (!teacher) {
      return res.status(404).json({
        success: false,
        message: "Teacher not found"
      });
    }

    const isMatch = await bcrypt.compare(
      password,
      teacher.password
    );

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Invalid password"
      });
    }

    const token = jwt.sign(
      {
        id: teacher.id,
        email: teacher.email,
        role: teacher.role
      },
      process.env.JWT_SECRET,
      {
        expiresIn: '7d'
      }
    );

    delete teacher.password;

    res.json({
      success: true,
      message: "Teacher login successful",
      token,
      data: teacher
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});

// ======================
// VIEW SESSION ATTENDANCE
// ======================

// IMPROVEMENT: Added teacherAuthMiddleware to protect this route
router.get('/session/:sessionId', teacherAuthMiddleware, async (req, res) => {
  try {
    const sessionId = parseInt(req.params.sessionId);

    const session = await prisma.session.findUnique({
      where: {
        id: sessionId
      },
      include: {
        attendance: {
          include: {
            student: true
          }
        }
      }
    });

    if (!session) {
      return res.status(404).json({
        success: false,
        message: "Session not found"
      });
    }

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

// ======================
// VIEW PENDING DEVICES
// ======================

router.get('/pending-devices', teacherAuthMiddleware, async (req,res)=>{
  try {
    const devices = await prisma.device.findMany({
      where: {
        isApproved: false
      },
      include: {
        student: true
      }
    });

    res.json({
      success: true,
      total: devices.length,
      data: devices
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});

// ======================
// APPROVE DEVICE
// ======================

router.post('/approve-device/:deviceId', teacherAuthMiddleware, async (req,res)=>{
  try {
    const deviceId = parseInt(req.params.deviceId);

    // Fetch device to get studentId
    const targetDevice = await prisma.device.findUnique({
      where: { id: deviceId }
    });

    if (!targetDevice) {
      return res.status(404).json({ success: false, message: "Device not found" });
    }

    const [device] = await prisma.$transaction([
      // 1. Approve and activate requested device
      prisma.device.update({
        where: { id: deviceId },
        data: { isApproved: true, isActive: true }
      }),
      // 2. Deactivate all other devices for this student
      prisma.device.updateMany({
        where: {
          studentId: targetDevice.studentId,
          id: { not: deviceId }
        },
        data: { isActive: false }
      })
    ]);

    res.json({
      success: true,
      message: "Device approved and previous devices deactivated",
      data: device
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});

// ======================
// REJECT DEVICE
// ======================

router.post('/reject-device/:deviceId', teacherAuthMiddleware, async (req,res)=>{
  try {
    const deviceId = parseInt(req.params.deviceId);

    const device = await prisma.device.findUnique({
      where: { id: deviceId }
    });

    if (!device) {
      return res.status(404).json({
        success: false,
        message: "Device not found"
      });
    }

    if (device.isApproved) {
      return res.status(400).json({
        success: false,
        message: "Cannot reject an already approved device"
      });
    }

    // Permanently delete the pending request
    await prisma.device.delete({
      where: { id: deviceId }
    });

    res.json({
      success: true,
      message: "Device request rejected and removed"
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
}); 

// ======================
// TEACHER DASHBOARD
// ======================

router.get('/dashboard', teacherAuthMiddleware, async (req, res) => {
  try {
    const teacherId = req.teacher.id;
    const now = new Date();

    // Today boundaries (midnight → midnight)
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);

    // ── Run all independent reads in parallel ──────────────────
    const [
      teacher,
      activeSession,
      totalStudents,
      totalSessions,
      pendingDevices,
      presentTodayRecords,
      studentAttendanceData,
    ] = await Promise.all([

      // 1. Teacher details
      prisma.teacher.findUnique({
        where: { id: teacherId },
        select: {
          id: true, name: true, email: true,
          department: true, role: true, createdAt: true,
        },
      }),

      // 2. Active session  (same logic as sessionRoutes /active)
      prisma.session.findFirst({
        where: {
          startTime: { lte: now },
          endTime:   { gte: now },
        },
      }),

      // 3. Total students
      prisma.student.count(),

      // 4. Total sessions
      prisma.session.count(),

      // 5. Pending device requests
      prisma.device.findMany({
        where: { isApproved: false },
        include: {
          student: {
            select: {
              id: true, name: true, email: true,
              rollNo: true, department: true,
            },
          },
        },
      }),

      // 6. Distinct students who marked attendance today
      prisma.attendance.groupBy({
        by: ['studentId'],
        where: { markedAt: { gte: startOfDay, lt: endOfDay } },
      }),

      // 7. All students with attendance counts
      prisma.student.findMany({
        include: {
          _count: { select: { attendance: true } },
        },
      }),
    ]);

    // ── Derived metrics ────────────────────────────────────────
    const presentToday = presentTodayRecords.length;
    const absentToday  = totalStudents - presentToday;

    const percentages = studentAttendanceData.map((s) =>
      totalSessions === 0
        ? 0
        : (s._count.attendance / totalSessions) * 100
    );

    const averageAttendance =
      percentages.length === 0
        ? 0
        : Number(
            (
              percentages.reduce((sum, p) => sum + p, 0) /
              percentages.length
            ).toFixed(2)
          );

    // Low-attendance students (< 75%)
    const lowAttendanceStudents = await Promise.all(studentAttendanceData
      .map(async (student) => {
        const attended = student._count.attendance;

        // Get total sessions applicable to this student
        const studentSessions = await prisma.session.count({
          where: {
            department: student.department,
            semester: student.semester,
            section: student.section
          }
        });

        const percentage =
          studentSessions === 0
            ? 0
            : (attended / studentSessions) * 100;

        return {
          id:          student.id,
          name:        student.name,
          rollNo:      student.rollNo,
          email:       student.email,
          department:  student.department,
          semester:    student.semester,
          section:     student.section,
          percentage:  Number(percentage.toFixed(2)),
          lowAttendance: percentage < 75,
        };
      }));

    const filteredLowAttendance = lowAttendanceStudents.filter((s) => s.lowAttendance);

    // ── Response ───────────────────────────────────────────────
    res.json({
      success: true,
      data: {
        teacher,
        activeSession: activeSession || null,
        statistics: {
          totalStudents,
          totalSessions,
          presentToday,
          absentToday,
          averageAttendance,
        },
        pendingDevices: pendingDevices,
        lowAttendanceStudents: filteredLowAttendance,
      },
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});

// teacher profile
router.get('/profile', teacherAuthMiddleware, async (req, res) => {
  try {
    const teacherId = req.teacher.id;

    // Run parallel reads
    const [
      teacher,
      totalStudents,
      totalSessions,
      pendingDevices,
      studentAttendanceData,
      activeSession
    ] = await Promise.all([
      prisma.teacher.findUnique({
        where: { id: teacherId },
        select: { id: true, name: true, email: true, department: true, role: true, createdAt: true }
      }),
      prisma.student.count(),
      prisma.session.count(),
      prisma.device.count({ where: { isApproved: false } }),
      prisma.student.findMany({
        include: { _count: { select: { attendance: true } } }
      }),
      prisma.session.findFirst({
        where: {
          startTime: { lte: new Date() },
          endTime: { gte: new Date() }
        }
      })
    ]);

    if (!teacher) {
      return res.status(404).json({ success: false, message: "Teacher not found" });
    }

    // Average attendance
    const percentages = studentAttendanceData.map(s =>
      totalSessions === 0 ? 0 : (s._count.attendance / totalSessions) * 100
    );
    const averageAttendance = percentages.length === 0 ? 0 :
      Number((percentages.reduce((sum, p) => sum + p, 0) / percentages.length).toFixed(2));

    res.json({
      success: true,
      data: {
        ...teacher,
        statistics: {
          totalStudents,
          totalSessions,
          pendingDevices,
          averageAttendance,
          isActiveSession: !!activeSession
        }
      }
    });

  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
