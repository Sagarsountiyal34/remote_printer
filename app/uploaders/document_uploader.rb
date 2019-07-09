class DocumentUploader < Shrine
  plugin :validation_helpers

  Attacher.validate do
    validate_min_size 50, message: "is too small (min is 50 Bytes)"
    validate_max_size 3*1024*1024, message: "is too large (max is 3 MB)"
    validate_mime_type_inclusion %w[application/msword application/vnd.oasis.opendocument.text application/pdf image/jpeg application/vnd.openxmlformats-officedocument.wordprocessingml.document]
    validate_extension_inclusion %w[doc odt pdf jpg docx]
  end
end