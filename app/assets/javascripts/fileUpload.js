$(document).ready(function() {
    $(document).on('click', '#continue_with_number', function(e) {
        if (check_all_form_valid()) {
            $('#phoneNumberVerification').modal('show');
        } else {
            notification("Please fill all entries.", "error")
        }
    });
    $(document).on('click', '#send_otp', function() {
        $(this).text('Please wait while we are sending.');
        $(this).attr('disabled', true);
        var phn_num = $('#phone_number').val();
        send_otp_to_phone_number(phn_num);
    });

    $(document).on('click', '#create_account_with_doc', function() {
        $(this).attr('disabled', true);
        $(this).text('Please Wait');
        var self = this;

        function onSuccess(response) {
            $('#phoneNumberVerification').modal('hide')
            if (response['message']['source'] == 'without_user') {
                $('#continue_with_number').show();
                $('#upload_submit_button').hide();
                $('#documents_form').find('form').attr('group_id', response['group_id'])
            }
            $('#loader_wrap_main').hide()
            $(self).text('Submit Selected');
            $(self).removeAttr('disabled');
            fillResponse(response);
        }

        function onError(error) {
            $('#loader_wrap_main').hide();
            notification(error["responseJSON"]["message"], "error");
            $(self).text('Submit Selected');
            $(self).removeAttr('disabled');
        }
        submitFormWithoutUser($('#new_upload_document'), onSuccess, onError);
    });

    function send_otp_to_phone_number(phone_number) {
        $.ajax({
            type: "POST",
            beforeSend: setCsrfToken, // implemented in application.html.erb
            url: "/send_otp_to_phone_number",
            data: { phone_number: phone_number },
            success: function(data) {
                if (data['status'] == true) {
                    $('#otp_span').show();
                    $('#phone_number_span').hide();
                    $('#send_otp').hide();
                    $('#create_account_with_doc').show();
                    notification("Please check OTP and Enter", "info");
                }
            },
            error: function(exception) {
                notification(JSON.parse(exception['responseText'])['message'], "error");
                $('#send_otp').text('Please wait while we are sending.');
                $('#send_otp').removeAttr('disabled');
            }
        });
    }


    function submitFormWithoutUser(form, success_cb, error_cb) {
        var history_data = ""
        var valuesToSubmit = new FormData(form.get(0));
        var document_ids = $('#history_list').find('.history_document').map(function() {
            return $(this).attr('id');
        }).get().join();
        var phone_number = $('#phone_number').val();
        var otp = $('#otp').val();
        valuesToSubmit.append('otp', otp);
        valuesToSubmit.append('phone_number', phone_number);
        valuesToSubmit.append('history_document_ids', document_ids);
        valuesToSubmit.append('company_id', $('#company').children('option:selected').val());
        $.ajax({
            type: "POST",
            beforeSend: setCsrfToken,
            url: $(form).attr('action'), //sumbits it to the given url of the form
            data: valuesToSubmit,
            processData: false,
            contentType: false,
            success: function(response) {
                if (success_cb) success_cb(response)
            },
            error: function(error) {
                if (error_cb) error_cb(error)
            }
        });
    }
    $(document).on('change', '.documentFileField', function(e) {
        $('#pdf_content').empty();
        var fileName = $(this).val().split('fakepath')[1].slice(1);
        //replace the "Choose a file" label
        var doc_name = fileName.split('.')[0];
        $(this).parents('.row').find('.document_name').val(doc_name);
        $(this).next('.custom-file-label').html(fileName);

        remove_empty_doc();

        var files = $(this)[0].files;
        var dT = new ClipboardEvent('').clipboardData || new DataTransfer();
        dT.items.add(files[0]);
        document.querySelector("[name='" + $(this).attr('name') + "']").files = dT.files;
        if (files.length > 1) {
            for (var i = 0; i < files.length - 1; i++) {
                if (i < files.length - 1) {
                    clone_doc_wrap();
                }
                fill_file_entry(files[i + 1]);
            }
        }
        if ($(this).get(0).files[0].type == "application/pdf") {
            $('.select_page_tag').val('all');
            $('.save_selected_page_button').hide();
            $(this).parents('.row').find('.page_selection_wrapper').show();
            readURL(this);
        } else {
            notification("Please upload a Image/PDF Files.", "error")
        }
    });


    function check_all_form_valid() {
        var status = true;
        $('#new_upload_document').find('.document').each(function(i, doc) {
            if ($(doc).find('input[type]:file').val() == '' || $(doc).find('input[type]:text').val() == '') {
                status = false
            }
        });
        return status;
    }

    $(document).on('click', '.remove_history_document', function() {
        $('#history_document').val().replace($(this).siblings('.history_document').attr('id'), '')
        $(this).parent('.history_document_wrapper').remove();
    });

    function fillResponse(res) {
        response = res;
        Object.keys(res['message']).forEach(function(key, value) {
            var doc = $('#documents_form').find('.document').get(parseInt(key));
            var class_name = ''
            if (response['message'][key][0] == true) {
                class_name = 'success_message';
            } else {
                class_name = 'error_message';
            }
            $(doc).find('.message').text(response['message'][key][1])
            $(doc).find('.message').addClass(class_name)
        });
    }

    function fill_file_entry(file) {
        var first_empty_input = get_index_of_first_empty_doc() + 1;
        if (first_empty_input != 0) {
            var doc_filename_input = 'upload_document[' + first_empty_input + '][document]'
            var file_ele = $('form').find("[name='" + doc_filename_input + "']")

            var dT = new ClipboardEvent('').clipboardData || new DataTransfer();
            dT.items.add(file);

            document.querySelector("[name='" + doc_filename_input + "']").files = dT.files;
            var fileName = $(file_ele).val().split('fakepath')[1].slice(1);
            //replace the "Choose a file" label
            var doc_name = fileName.split('.')[0];
            $(file_ele).parents('.row').find('.document_name').val(doc_name);
            $(file_ele).next('.custom-file-label').html(fileName);
        }
    }

    $(document).on('click', '#add_more_button', function() {
        clone_doc_wrap();
    });

    function clone_doc_wrap() {
        var new_doc = $(".document").first().clone();
        var total_doc = $('#documents_form').find('.document').length
        var label_name_for = $(new_doc).find('label').attr('for') + (total_doc + 1).toString();
        var new_select_name = 'upload_document[' + (total_doc + 1).toString() + '][print_type]'
        var document_name = 'upload_document[' + (total_doc + 1).toString() + '][document_name]';
        var document_name_id = $(new_doc).find('#upload_document_document_name').attr('id') + (total_doc + 1).toString();
        var document_file_name = 'upload_document[' + (total_doc + 1).toString() + '][document]';
        $(new_doc).find('input[type=text]').attr('id', document_name_id);
        $(new_doc).find('input[type=text]').attr('name', document_name).val('');
        $(new_doc).find('input[type=file]').attr('name', document_file_name).val('');
        $(new_doc).find('select').attr('name', new_select_name).val('');
        $(new_doc).find('select').children().first().attr('selected', 'selected');
        $(new_doc).find('label').attr('for', label_name_for);
        $(new_doc).find('input[type=file]').attr('id', label_name_for)
        $(new_doc).find('label[class=custom-file-label]').html('File');
        $(new_doc).find('.page_details').val('all')
        $(new_doc).find('.page_details').attr('name', 'upload_document[' + (total_doc + 1) + '][page_detail]')
        $('<i>').attr({ class: 'fas fa-times remove_form fa-2x col-1', style: "cursor:pointer;color:red;" }).insertBefore(new_doc.find('.message'));
        $('#documents_wrap').append(new_doc);
    }


    function get_index_of_first_empty_doc() {
        var index = 0;
        $('#new_upload_document').find('.document').each(function(i, doc) {
            if (i == 0) { return; }
            if ($(doc).find('input[type]:file').val() == '' || $(doc).find('input[type]:text').val() == '') {
                index = i;
                return false;
            }
        });
        return index;
    }




    function remove_empty_doc() {
        var i = 0;
        $('#new_upload_document').find('.document').each(function(i, doc) {
            if (i == 0) { return; }
            if ($(doc).find('input[type]:file').val() == '' || $(doc).find('input[type]:text').val() == '') {
                $(this).remove();
            }
            i++;
        });
    }




    $(document).on('click', '.remove_form', function() {
        $(this).parent('.document').remove();

    });

    function readURL(input) {
        if (input.files && input.files[0]) {
            $('#selectPageWrapper').attr('file_input_id', $(input).attr('id'));
            var reader = new FileReader();
            var file = input.files[0];
            reader.onload = function(e) {
                var typedarray = new Uint8Array(this.result);
                renderPDF(typedarray);
                $('#selectPageWrapper').modal('show');
                // $('#selectPageWrapper').modal('hide');

            }
            reader.readAsArrayBuffer(file);
        }
    }

    function renderPDF(url) {
        pdfjsLib.getDocument(url)
            .then(function(pdf) {
                var container = document.getElementById("pdf_content");
                for (var i = 1; i <= pdf.numPages; i++) {
                    pdf.getPage(i).then(function(page) {
                        var scale = 1.5;
                        var width_for_pdf = document.getElementById("selectPageModalContent").offsetWidth - 10
                        var viewport = page.getViewport(width_for_pdf / page.getViewport(1.0).width);
                        var div = document.createElement("div");
                        div.setAttribute("id", "page-" + (page.pageIndex + 1));
                        div.setAttribute("style", "position: relative");
                        container.appendChild(div);
                        var canvas = document.createElement("canvas");
                        var page_number_div = $("<div class='checkbox_wrap' style='text-align: center;background-color: background-color: transparent;background-color: #24292e;font-size: x-large;'>" + (page.pageIndex + 1) + "/" + pdf.numPages + "</div>");
                        div.appendChild(page_number_div.get(0));
                        div.appendChild(canvas);
                        var checkbox_wrap = $("<div class='checkbox_wrap' style='display:none;'></div>");
                        var new_checkbox = $("<input  type='checkbox' class='select_page_check_box' id='" + (page.pageIndex + 1) + "'>");
                        var new_checkbox_label = $("<label for='select_page_" + (page.pageIndex + 1) + "'>Select Page " + (page.pageIndex + 1) + "</label>'");
                        checkbox_wrap.append(new_checkbox)
                        checkbox_wrap.append(new_checkbox_label)
                        div.appendChild(checkbox_wrap.get(0));
                        // div.appendChild(new_checkbox_label.get(0));

                        var context = canvas.getContext('2d');
                        canvas.height = viewport.height;
                        canvas.width = viewport.width;

                        var renderContext = {
                            canvasContext: context,
                            viewport: viewport
                        };
                        page.render(renderContext);
                    });
                }
            });

    }

    $(document).on('click', '#upload_submit_button', function(e) {
        var total_count = $('.document').length;
        var success_count = 0;
        var count = 1;
        var self = this;
        $('#loader_wrap_main').show();
        $(this).text('Please wait');
        $(this).attr('disabled', 'true');
        var check_if_valid = check_all_form_valid();
        if ($('#history_document').val() != '' && $('#new_upload_document').find('.document').length == 1) {
            check_if_valid = true
        }
        if (check_if_valid == true) {
            submitForm($('form'), onSuccess, onError);
        } else {
            $('#loader_wrap_main').hide()
            $(this).text('Submit Selected');
            $(this).removeAttr('disabled');
            notification("Please fill all entries.", "error")
        }

        function onSuccess(response) {
            $('#loader_wrap_main').hide()
            $(self).text('Submit Selected');
            $(self).removeAttr('disabled');
            fillResponse(response);
        }

        function onError(error) {
            $('#loader_wrap_main').hide()
            $(this).text('Submit Selected');
            $(this).removeAttr('disabled');
        }
    });

    function submitForm(form, success_cb, error_cb) {
        var history_data = ""
        var valuesToSubmit = new FormData(form.get(0));
        var document_ids = $('#history_list').find('.history_document').map(function() {
            return $(this).attr('id');
        }).get().join();
        valuesToSubmit.append('history_document_ids', document_ids);
        valuesToSubmit.append('company_id', $('#company').children('option:selected').val());
        $.ajax({
            type: "POST",
            beforeSend: setCsrfToken,
            url: $(form).attr('action'), //sumbits it to the given url of the form
            data: valuesToSubmit,
            processData: false,
            contentType: false,
            success: function(response) {
                if (success_cb) success_cb(response)
            },
            error: function(error) {
                if (error_cb) error_cb(error)
            }
        });
    }

    // for desktop doc upload
    $(document).on('change', '.uploadDocumentDesktop', function(e) {
        $('.page_details').val('all');
        var fileName = $(this).val().split('fakepath')[1].slice(1);
        //replace the "Choose a file" label
        var doc_name = fileName.split('.')[0];
        $(this).parents('form').find('.doc_name').val(doc_name);
        if ($(this).get(0).files[0].type == "application/pdf") {
            $('.select_page_tag').val('all');
            $('.save_selected_page_button').hide();
            $(this).parents('.row').find('.page_selection_wrapper').show();
            readURL(this);
        } else {
            notification("Please upload a Image/PDF Files.", "error")
        }
    })

});