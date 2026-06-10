module Admin
  class FaqBlocksController < Admin::ApplicationController
    before_action :find_page
    before_action :find_faq_block, only: %i[edit update destroy]

    # GET /admin/pages/:page_id/faq_blocks
    def index
      @faq_blocks = @page.faq_blocks
      authorize FaqBlock, :create?
    end

    # GET /admin/pages/:page_id/faq_blocks/new
    def new
      @faq_block = @page.faq_blocks.build
      authorize @faq_block
    end

    # POST /admin/pages/:page_id/faq_blocks
    def create
      @faq_block = @page.faq_blocks.build(faq_block_params)
      authorize @faq_block
      if @faq_block.save
        redirect_to admin_page_faq_blocks_path(@page), notice: "FAQ item added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin/pages/:page_id/faq_blocks/:id/edit
    def edit
    end

    # PATCH /admin/pages/:page_id/faq_blocks/:id
    def update
      if @faq_block.update(faq_block_params)
        redirect_to admin_page_faq_blocks_path(@page), notice: "FAQ item updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin/pages/:page_id/faq_blocks/:id
    def destroy
      @faq_block.destroy
      redirect_to admin_page_faq_blocks_path(@page), notice: "FAQ item deleted."
    end

    private

    def find_page
      @page = Page.friendly.find(params[:page_id])
    end

    def find_faq_block
      @faq_block = @page.faq_blocks.find(params[:id])
      authorize @faq_block
    end

    def faq_block_params
      params.require(:faq_block).permit(:question, :answer, :position)
    end
  end
end
