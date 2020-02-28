module GroupHelper
	def group_total(group)
		return group.documents.map(&:cost).inject('+')
	end

	def get_net_cost_of_groups(group)
		 group.documents.where(:status => 'completed').sum('cost')
	end
end
