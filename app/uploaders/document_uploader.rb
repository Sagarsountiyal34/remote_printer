class DocumentUploader < Shrine
  plugin :validation_helpers

  Attacher.validate do
    validate_min_size 50, message: "is too small (min is 50 Bytes)"
    validate_max_size 20*1024*1024, message: "is too large (max is 20 MB)"
    # validate_mime_type_inclusion %w[application/msword application/vnd.oasis.opendocument.text application/pdf  application/vnd.openxmlformats-officedocument.wordprocessingml.document image/png image/jpeg image/gif]
    # validate_mime_type_inclusion %w[*]
    # validate_extension_inclusion %w[doc odt pdf docx png jpg jpeg gif]
    # validate_extension_inclusion %w[*]
  end
end
