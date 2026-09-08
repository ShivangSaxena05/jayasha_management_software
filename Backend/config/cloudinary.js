const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const multer = require('multer');

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: async (req, file) => {
    // Determine folder based on route or fieldname
    let folder = 'school_management';
    if (file.fieldname === 'principal_photo') folder += '/principal/photos';
    else if (file.fieldname === 'principal_aadhaar') folder += '/principal/aadhaar';
    else if (file.fieldname === 'teacher_photo') folder += '/teachers/photos';
    else if (file.fieldname === 'teacher_aadhaar') folder += '/teachers/aadhaar';
    else if (file.fieldname === 'student_photo') folder += '/students/photos';
    else if (file.fieldname === 'staff_photo') folder += '/staff/photos';

    return {
      folder: folder,
      allowed_formats: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      public_id: `${Date.now()}-${file.originalname.split('.')[0]}`,
    };
  },
});

const upload = multer({ storage: storage });

module.exports = { cloudinary, upload };
