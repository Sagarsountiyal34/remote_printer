module GroupHelper
	def group_total(group)
		return group.documents.map(&:cost).inject('+')
	end
end
