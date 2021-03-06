class PledgesController < ApplicationController
  before_action :load_project

  def index
    @pledges = Pledge.all
  end

  def show
    @pledge = Pledge.find(params[:id])
  end

  def new
    @pledge = Pledge.new
  end

  def create

    unless params[:pledge][:amount].to_i > @project.funding_goal

      @pledge = @project.pledges.build(pledge_params)
      @pledge.backer = current_user
      @pledge.get_reward?(@project)

      if @pledge.save

        respond_to do |format|
          format.html{ redirect_to project_path(@project), notice: 'Pledge successfully updated.' }
          format.js
        end

      else

        respond_to do |format|
          format.html{ render :new, notice: "Pledge not successfully submitted!" }
          format.js
        end

      end

      # if @project.fully_funded?
      #   @project.backers.each do |backer|
      #     UserMailer.notify_fully_funded(backer, @project).deliver_later
      #   end
      # end

    else
      @pledge = Pledge.new
      respond_to do |format|
        format.html{ redirect_to project_path(@project), notice: 'Pledge successfully updated.' }
        format.js
      end

      #render a message telling the user the total amount they can pledge
      #the user should only be able to pledge the value in the distance to goal field.
      flash[:alert] = "We'd love to take you money!! But we don't need that much!"
    end

  end

  def edit
    @pledge = Pledge.find(params[:id])
  end

  def update
    @pledge = Pledge.find(params[:id])

    unless (params[:pledge][:amount].to_i + @project.pledges.all.sum(:amount)) > @project.funding_goal

      @existing = @pledge.amount
      @pledge.update_attributes(pledge_params) #Updates @pledge with new amount value
      @pledge.amount += @existing

      if @pledge.save

        respond_to do |format|
          format.html{ redirect_to project_path(@project), notice: 'Pledge successfully updated.' }
          format.js
        end

        @pledge.get_reward?(@project)

        if @project.fully_funded?
          @project.backers.each do |backer|
            UserMailer.notify_fully_funded(backer, @project).deliver_later
          end
        end

      else
        # render :edit
      end

    else
      respond_to do |format|
        format.html
        format.js
      end
    end

  end


  def destroy
    @pledge = Pledge.find(params[:id])
    @pledge.destroy
    flash[:notice] = "Pledge successfully deleted."
    redirect_to project_pledges_path
  end

  private

  def pledge_params
    params.require(:pledge).permit(:amount)
  end

  def load_project
    @project = Project.find(params[:project_id])
  end

end
