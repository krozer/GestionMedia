class SeedSubCategories < ActiveRecord::Migration[8.0]
  def change
    SubCategory.create!([
      { code: 2184, label: 'Série TV' },
      { code: 2179, label: 'Série Animé' },
      { code: 2183, label: 'Film' },
      { code: 2178, label: 'Animation' }
    ])
  end
end
