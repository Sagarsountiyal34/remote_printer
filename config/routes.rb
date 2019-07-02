Rails.application.routes.draw do
  get 'group/view'
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }
	root to: 'groups#new'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get 'upload_doc', to: 'groups#new'
  post 'save_group', to: 'groups#create'
  post 'update_group', to: 'groups#update'
  get 'edit_group/:id', to: 'groups#edit'
  get 'list_documents', to: 'documents#list_documents'
  get 'printed_groups', to: 'groups#list'
  post 'add_document_to_group', to: 'groups#add_document_to_group'
  post 'remove_document_from_group', to: 'groups#remove_document_from_group'
  post 'remove_documents', to: 'documents#remove_documents'
  post 'start_payment', to: 'groups#start_payment'



  namespace 'api' do
		namespace 'v1' do
			get 'get_all_documents', to: 'documents#get_all_documents'
			post 'update_document_and_group_status', to: 'documents#update_document_and_group_status', as: 'update_document_and_group_status'
		end
	end
end
