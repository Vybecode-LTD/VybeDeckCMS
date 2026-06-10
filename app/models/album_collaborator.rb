class AlbumCollaborator < ApplicationRecord
  belongs_to :album
  belongs_to :user

  enum :role, { producer: 0, engineer: 1, artist: 2, manager: 3 }

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :album_id, message: "is already a collaborator on this album" }
end
