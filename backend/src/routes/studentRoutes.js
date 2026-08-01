const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const router = express.Router();
const prisma = require('../config/db');
const {
  validateSignup,
  validateLogin
} = require('../validators/studentValidator');

const authMiddleware = require('../middleware/authMiddleware');

// signup
router.post('/signup', validateSignup, async (req, res) => {
  try {
    const { name, password, email, rollNo, department, semester, section } = req.body;
    // check existing
    const existing = await prisma.student.findFirst({
      where: {
        OR: [
          { email },
          { rollNo }
        ]
      }
    });

    if (existing) {
      return res.status(400).json({
        success: false,
        message: "Email or Roll Number already exists"
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    // create student
    const student = await prisma.student.create({
      data: {
        name,
        email,
        password: hashedPassword,
        rollNo,
        department,
        semester,
        section
      }
    });

    delete student.password;

    res.status(201).json({
      success: true,
      data: student
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});

// login
router.post('/login', validateLogin, async (req, res) => {
  try {
    const { email, password } = req.body;

    const student = await prisma.student.findUnique({
      where: { email },
      include: { devices: true }
    });

    if (!student) {
      return res.status(404).json({
        success: false,
        message: "Student not found"
      });
    }

    // password verification
    const isMatch = await bcrypt.compare(password, student.password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Invalid password"
      });
    }

    // Generate token
    const token = jwt.sign(
      {
        id: student.id,
        email: student.email
      },
      process.env.JWT_SECRET,
      {
        expiresIn: '7d'
      }
    );

    // Remove password from response
    delete student.password;

    const { uuid, deviceHash } = req.body;

    if (uuid && deviceHash) {
      // 1. check if device already registered for this student
      const existingDevice = student.devices.find(
        d => d.uuid === uuid && d.deviceHash === deviceHash
      );

      if (!existingDevice) {
        // 2. if no devices at all, auto-register and approve (First login flow)
        if (student.devices.length === 0) {
          await prisma.$transaction([
            // Deactivate any existing approved devices (safety measure)
            prisma.device.updateMany({
              where: { studentId: student.id, isApproved: true },
              data: { isActive: false }
            }),
            // Create and activate new device
            prisma.device.create({
              data: {
                uuid,
                deviceHash,
                studentId: student.id,
                isApproved: true,
                isActive: true
              }
            })
          ]);
        } else {
          // 3. if student already has other devices, this one needs approval
          // check if pending request already exists
          const pendingDevice = await prisma.device.findFirst({
            where: {
              uuid,
              deviceHash,
              studentId: student.id
            }
          });

          if (!pendingDevice) {
            await prisma.device.create({
              data: {
                uuid,
                deviceHash,
                studentId: student.id,
                isApproved: false,
                isActive: false
              }
            });
          }

          return res.status(403).json({
            success: false,
            message: "New device request submitted for approval",
            token,
            data: student
          });
        }
      } else if (!existingDevice.isApproved || !existingDevice.isActive) {
        // 4. device exists but is not approved or active
        return res.status(403).json({
          success: false,
          message: "Device approval pending or inactive",
          token,
          data: student
        });
      }
    }

    res.json({
      success: true,
      message: "Login successful",
      token,
      data: student
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});

// profile
router.get('/profile', authMiddleware, async (req, res) => {
  try {
    const studentId = req.user.id;

    const student = await prisma.student.findUnique({
      where: { id: studentId },
      include: {
        devices: true,
        _count: {
          select: { attendance: true }
        }
      }
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

    const attended = student._count.attendance;
    const percentage = totalSessions === 0 ? 0 : ((attended / totalSessions) * 100).toFixed(2);

    delete student.password;

    res.json({
      success: true,
      data: {
        ...student,
        statistics: {
          totalSessions,
          attended,
          percentage: Number(percentage)
        }
      }
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});

module.exports = router;
