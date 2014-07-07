module SortablePosts
  extend ActiveSupport::Concern

  private

  def map_sort_key(key, default)
    map = {id: "id",
           id_desc: "id DESC",
           topic_id: "topic_id",
           topic_id_desc: "topic_id DESC",
           user_id: "user_id",
           user_id_desc: "user_id DESC",
           remote_created_at: "remote_created_at",
           remote_created_at_desc: "remote_created_at DESC",
           remote_id: "remote_id",
           remote_id_desc: "remote_id DESC"}
    map[key.try(:to_sym)] || map[default.to_sym]
  end
end
