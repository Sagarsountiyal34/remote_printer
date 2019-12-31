class CompaniesController < ApplicationController
	before_action :authenticate_user!
	protect_from_forgery prepend: true

	def new
		@company = Company.new
	end
	
	def create
		company = Company.new(params.require(:company).permit(:company_name, :password))
		if company.save
			redirect_to action: 'index'
		else
		
		end
	end
	
	def index
		@companies = Company.all
	end
end