class Admin::YggsController < ApplicationController
  def index
    @yggs = Ygg.where(tmdb_id: nil)
  end

  def edit
    @ygg = Ygg.find(params[:id])
    @tmdb_results = @ygg.search_tmdb || []
  end

  def update
    @ygg = Ygg.find(params[:id])
    if @ygg.update(tmdb_id: params[:ygg][:tmdb_id])
      redirect_to admin_yggs_path, notice: "Ygg #{@ygg.id} mis à jour avec succès."
    else
      render :edit
    end
  end
end
