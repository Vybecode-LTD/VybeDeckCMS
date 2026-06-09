module Admin
  class ForumThreadsController < Admin::ApplicationController
    # Standard CRUD handled by Administrate::Punditize.

    # PATCH /admin/forum_threads/:id/lock — toggle locked state
    def lock
      thread = ForumThread.find(params[:id])
      authorize thread, :lock?
      thread.update!(locked: !thread.locked?)
      redirect_to admin_forum_thread_path(thread),
                  notice: thread.locked? ? "Thread locked." : "Thread unlocked."
    end

    # PATCH /admin/forum_threads/:id/pin — toggle pinned state
    def pin
      thread = ForumThread.find(params[:id])
      authorize thread, :pin?
      thread.update!(pinned: !thread.pinned?)
      redirect_to admin_forum_thread_path(thread),
                  notice: thread.pinned? ? "Thread pinned." : "Thread unpinned."
    end
  end
end
