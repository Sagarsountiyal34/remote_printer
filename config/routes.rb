Rails.application.routes.draw do
  get 'group/view'
  # devise_for :users
	root to: 'home#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/admin' =>"admins#dashboard"
  resource :admins do
    get '/users' =>"admins#users"
    get "/user_list", to: "admins#user_list"
  end


  resources :companies
  resources :discounts

  #------------------ Search ------------------
  get "/search",to: "search#show"
    Rails.application.routes.draw do

        devise_for :users, controllers: {
            registrations: 'users/registrations',
            sessions: 'users/sessions',
          passwords: 'users/passwords'
        }
        # devise_scope :user do
        #     post 'users/create_customer', to: 'users/registrations#create_customer'
        # end
    end
  #------------------- end --------------------

  #---------------- Home url's ----------------

  # get "/home",to: "home#home"
  get "/about",to: "home#about_us"
  get "/contact",to: "home#contact"
  post "/contact",to: "home#contact"
  get "/confirm_otp",to: "home#confirm_otp"
  get "/all_users", to: "admins#dashboard"
  post "/save_otp",to: "home#save_confirmable_otp"
  get "/users/:id", to: "users#show", as: 'show_user'

  #------------------ End ---------------------

  get 'upload_doc', to: 'groups#new'
  post 'save_group', to: 'groups#create'
  post 'save_docs', to: 'documents#save_doc_without_user'
  post 'update_group', to: 'groups#update'
  get 'edit_group/:id', to: 'groups#edit', as: 'group_page'
  get 'list_documents', to: 'documents#list_documents'
  post 'create_account_with_group', to: 'users#create_account_with_group'
  get 'get_documents', to: 'documents#get_documents'
  get 'get_documents_for_history', to: 'groups#get_documents_for_history'
  get 'printed_groups', to: 'groups#list'
  get 'progress_groups', to: 'groups#progress_groups'
  get 'recently_printed_groups', to: 'groups#recently_printed_groups'
  post 'add_document_to_group', to: 'groups#add_document_to_group'
  post 'remove_document_from_group', to: 'groups#remove_document_from_group'
  post 'remove_documents', to: 'documents#remove_documents'
  post 'start_payment', to: 'groups#start_payment'
  post 'payment_response', to: 'groups#payment_response'
  post 'apply_disapply_discount', to: 'discounts#apply_disapply_discount'
  post 'send_otp_to_phone_number', to: 'users#send_otp_to_phone_number'
  post 'proceed_to_payment', to: 'groups#proceed_to_payment'
  post 'approve_disapprove_group_doc', to: 'groups#approve_disapprove_group_doc'
  post 'create_pdf_with_selected_page', to: 'groups#create_pdf_with_selected_page'

  namespace 'api' do
		namespace 'v1' do
      mount_devise_token_auth_for 'Company', at: 'auth'

      post 'get_all_documents', to: 'documents#get_all_documents'
			post 'update_document_status', to: 'documents#update_document_status', as: 'update_document_status'
      post 'update_group_status', to: 'documents#update_group_status', as: 'update_group_status'
      post 'get_groups_with_status', to: 'documents#get_groups_with_status'
      get 'get_groups_wd_status', to: 'groups#get_groups_wd_status'
      post 'mark_all_as_printed', to: 'groups#mark_all_as_printed'
      post 'print_group_again', to: 'groups#print_group_again'
      post 'send_error_to_admin', to: 'documents#send_error_to_admin'
      post 'print_document', to: 'documents#print_document'
      get 'print_document2', to: 'documents#print_document2'
      get 'fetch_in_printing_doc_to_print', to: 'documents#fetch_in_printing_doc_to_print'
      post 'mark_document_as_printed',to: 'documents#mark_document_as_printed'
      post 'suggestions_for_user_email', to: 'search#suggestions_for_user_email'
      post 'suggestions_for_Document_names', to: 'search#suggestions_for_Document_names'
      post 'suggestions_for_otps', to: 'search#suggestions_for_otps'
      post 'search_by_category', to: 'search#search_by_category'
      post 'search_in_user_list', to: 'search#search_in_user_list'
      post 'users/list', to: 'users#list'
      post 'groups/get_groups_with_document_status', to: 'groups#get_groups_with_document_status'
      post 'notes/save_note', to: 'notes#save_note'
      get 'notes/get_note', to: 'notes#get_note'
      get 'users_list',to:'users#users_list'
      get 'pending_payments',to: 'users#pending_payments'
      get 'check_user_confirmed',to: 'users#check_user_confirmed'
      post 'change_document_status', to: 'documents#change_document_status' # not present



      post 'change_status_and_active', to: 'documents#change_status_and_active'
      get 'change_progress_page_count', to: 'documents#change_progress_page_count'
      get 'get_doc_to_print', to: 'documents#get_doc_to_print'
      get 'fetch_document_to_print', to: 'documents#fetch_document_to_print'
      get 'get_document_details', to: 'documents#get_document_details'
      post 'check_company_credential', to: 'users#check_company_credential'
      post 'change_paid_status',to: "groups#change_paid_status"
      post 'update_printer_setting',to: "printer_settings#update_printer_setting"
      get 'get_current_printer_name',to: "printer_settings#get_current_printer_name"
      get 'get_current_printer_settings',to: "printer_settings#get_current_printer_settings"
      post 'update_printer_cost',to: "printer_settings#update_printer_cost"
      post 'update_doc_print_type',to: "documents#update_doc_print_type"
      post 'interrupt_document',to: 'documents#interrupt_cancel_document'
      post 're_print_doc',to: 'documents#re_print_doc'
      get 'print_next_doc_from_group',to: 'groups#print_next_doc_from_group'
      post 'set_status_on_start',to: "documents#set_status_on_start"
      post 'set_doc_status',to: "documents#set_doc_status"
      get 'get_document_details_only', to: "documents#get_document_details_only"
		end
	end
end
