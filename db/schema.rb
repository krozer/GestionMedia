# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_01_28_161432) do
  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "genres", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "genres_tmdb_movies", id: false, force: :cascade do |t|
    t.integer "tmdb_movie_id", null: false
    t.integer "genre_id", null: false
    t.index ["genre_id"], name: "index_genres_tmdb_movies_on_genre_id"
    t.index ["tmdb_movie_id"], name: "index_genres_tmdb_movies_on_tmdb_movie_id"
  end

  create_table "genres_tmdb_tvs", force: :cascade do |t|
    t.integer "tmdb_tv_id", null: false
    t.integer "genre_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["genre_id"], name: "index_genres_tmdb_tvs_on_genre_id"
    t.index ["tmdb_tv_id"], name: "index_genres_tmdb_tvs_on_tmdb_tv_id"
  end

  create_table "plex_movies", force: :cascade do |t|
    t.string "titre", null: false
    t.string "name"
    t.integer "annee"
    t.string "langue"
    t.string "source"
    t.string "resolution"
    t.string "codec"
    t.string "audio"
    t.string "canaux"
    t.integer "size"
    t.integer "tmdb_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sub_categories", force: :cascade do |t|
    t.integer "code", null: false
    t.string "label", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "category_id"
    t.index ["category_id"], name: "index_sub_categories_on_category_id"
    t.index ["code"], name: "index_sub_categories_on_code", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.string "pattern"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tags_ygg_movies", id: false, force: :cascade do |t|
    t.integer "ygg_movie_id", null: false
    t.integer "tag_id", null: false
  end

  create_table "tags_ygg_tvs", force: :cascade do |t|
    t.integer "ygg_tv_id", null: false
    t.integer "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_tags_ygg_tvs_on_tag_id"
    t.index ["ygg_tv_id"], name: "index_tags_ygg_tvs_on_ygg_tv_id"
  end

  create_table "tmdb_movies", force: :cascade do |t|
    t.string "title"
    t.date "release_date"
    t.text "overview"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "adult"
    t.string "backdrop_path"
    t.string "original_language"
    t.string "original_title"
    t.float "popularity"
    t.string "poster_path"
    t.boolean "video"
    t.float "vote_average"
    t.integer "vote_count"
    t.boolean "watchlist", default: false
    t.datetime "vu"
  end

  create_table "tmdb_tvs", force: :cascade do |t|
    t.string "name"
    t.string "original_name"
    t.date "first_air_date"
    t.string "origin_country"
    t.string "backdrop_path"
    t.string "poster_path"
    t.text "overview"
    t.float "popularity"
    t.float "vote_average"
    t.integer "vote_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "watchlist", default: false
  end

  create_table "tmdb_watchlists", force: :cascade do |t|
    t.integer "tmdb_id"
    t.string "media_type"
    t.string "title"
    t.date "release_date"
    t.text "overview"
    t.string "poster_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tmdbs", force: :cascade do |t|
    t.string "title", null: false
    t.date "release_date"
    t.text "overview"
    t.string "poster_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ygg_movies", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.integer "sub_category"
    t.integer "size"
    t.datetime "added_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tmdb_id"
    t.integer "annee"
    t.integer "saison"
    t.integer "episode"
    t.string "source"
    t.string "resolution"
    t.string "langue"
    t.string "codec"
    t.string "audio"
    t.string "canaux"
    t.string "titre"
  end

  create_table "ygg_tvs", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.integer "sub_category"
    t.integer "size"
    t.datetime "added_date"
    t.integer "tmdb_tv_id"
    t.integer "annee"
    t.integer "saison"
    t.integer "episode"
    t.string "source"
    t.string "resolution"
    t.string "langue"
    t.string "codec"
    t.string "audio"
    t.string "canaux"
    t.string "titre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tmdb_tv_id"], name: "index_ygg_tvs_on_tmdb_tv_id"
  end

  add_foreign_key "genres_tmdb_movies", "genres"
  add_foreign_key "genres_tmdb_tvs", "genres"
  add_foreign_key "genres_tmdb_tvs", "tmdb_tvs"
  add_foreign_key "plex_movies", "tmdb_movies", column: "tmdb_id"
  add_foreign_key "sub_categories", "categories"
  add_foreign_key "tags_ygg_movies", "tags"
  add_foreign_key "tags_ygg_movies", "ygg_movies"
  add_foreign_key "tags_ygg_tvs", "tags"
  add_foreign_key "tags_ygg_tvs", "ygg_tvs"
  add_foreign_key "ygg_movies", "tmdb_movies", column: "tmdb_id"
  add_foreign_key "ygg_tvs", "tmdb_tvs"
end
