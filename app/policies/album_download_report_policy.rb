class AlbumDownloadReportPolicy < ApplicationPolicy
  def show?; admin_accessible?; end
end
