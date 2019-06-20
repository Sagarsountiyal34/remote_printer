Rails.application.routes.draw do
  get 'group/view'
  devise_for :users
	root to: 'users#list_documents'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'upload_document', to: 'users#upload_document'
  post 'save_document', to: 'users#save_document'
  get 'list_documents', to: 'users#list_documents'
  post 'add_document_to_group', to: 'groups#add_document_to_group'
  post 'remove_document_from_group', to: 'groups#remove_document_from_group'
  post 'remove_documents', to: 'documents#remove_documents'
  get 'list_group_documents', to: 'groups#list'

  namespace 'api' do
		namespace 'v1' do
			get 'get_all_documents', to: 'documents#get_all_documents'
			post 'update_document_status/:id', to: 'documents#update_document_status', as: 'update_document_status'
		end
	end
end
