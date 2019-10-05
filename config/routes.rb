Rails.application.routes.draw do
  get 'group/view'
  devise_for :users
	root to: 'home#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/admin' =>"admins#dashbord"
  resource :admins do
    get '/users' =>"admins#users"
  end
  #------------------ Search ------------------
  get "/search",to: "search#show"

  #------------------- end --------------------

  #---------------- Home url's ----------------

  # get "/home",to: "home#home"
  get "/about",to: "home#about_us"
  get "/contact",to: "home#contact"

  #------------------ End ---------------------

  get 'upload_doc', to: 'groups#new'
  post 'save_group', to: 'groups#create'
  post 'update_group', to: 'groups#update'
  get 'edit_group/:id', to: 'groups#edit'
  get 'list_documents', to: 'documents#list_documents'
  get 'get_documents', to: 'documents#get_documents'
  get 'get_documents_for_history', to: 'groups#get_documents_for_history'
  get 'printed_groups', to: 'groups#list'
  get 'progress_groups', to: 'groups#progress_groups'
  get 'recently_printed_groups', to: 'groups#recently_printed_groups'
  post 'add_document_to_group', to: 'groups#add_document_to_group'
  post 'remove_document_from_group', to: 'groups#remove_document_from_group'
  post 'remove_documents', to: 'documents#remove_documents'
  post 'start_payment', to: 'groups#start_payment'

  post 'proceed_to_payment', to: 'groups#proceed_to_payment'


  namespace 'api' do
		namespace 'v1' do
			post 'get_all_documents', to: 'documents#get_all_documents'
			post 'update_document_status', to: 'documents#update_document_status', as: 'update_document_status'
      post 'update_group_status', to: 'documents#update_group_status', as: 'update_group_status'
      post 'get_groups_with_status', to: 'documents#get_groups_with_status'
      post 'get_groups_wd_status', to: 'groups#get_groups_wd_status'
      post 'mark_all_as_printed', to: 'groups#mark_all_as_printed'
      post 'print_group_again', to: 'groups#print_group_again'
      post 'send_error_to_admin', to: 'documents#send_error_to_admin'
      post 'print_document', to: 'documents#print_document'
      get 'print_document2', to: 'documents#print_document2'
      get 'fetch_in_printing_doc_to_print', to: 'documents#fetch_in_printing_doc_to_print'
		end
	end
end
