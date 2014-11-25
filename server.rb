require 'sinatra'
require 'pg'
require 'pry'
require 'sinatra/reloader'

def db_connection
  begin
    connection = PG.connect(dbname: 'movies')

    yield(connection)

  ensure
    connection.close
  end
end

get '/actors' do
  db_connection do |connection|
    @actors = connection.exec("SELECT name, id FROM actors ORDER BY name")
    @actors_count = connection.exec("SELECT count(id) FROM actors")[0]['count'].to_f
    if params[:page]
      @end_page = 30 * params[:page].to_i - 1
      @page = params[:page].to_i
      @start_page = @end_page - 29
    else
      @start_page = 0
      @end_page = 29
      @page = 1
    end


    @last_page = @actors_count / 30

  end
  erb :'actors/index'
end

get '/actors/:id' do
  @id = params[:id]
  db_connection do |connection|

    @actor_info = connection.exec_params("SELECT cast_members.character,
    movies.title, actors.name, movies.id AS movie_id FROM actors
    LEFT OUTER JOIN cast_members ON cast_members.actor_id = actors.id
    LEFT OUTER JOIN movies ON movies.id = cast_members.movie_id
    WHERE actors.id = $1", [@id])
  end

  erb :'actors/show'
end

get '/movies' do

  db_connection do |connection|
    @movies = connection.exec("SELECT movies.id AS movie_id, movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio
    FROM movies
    LEFT OUTER JOIN genres ON movies.genre_id = genres.id
    LEFT OUTER JOIN studios ON movies.studio_id = studios.id
    ORDER BY movies.title")
    @movies_count = connection.exec("SELECT count(id) FROM movies")[0]['count'].to_f
    if params[:page]
      @end_page = 30 * params[:page].to_i - 1
      @page = params[:page].to_i
      @start_page = @end_page - 29
    else
      @start_page = 0
      @end_page = 29
      @page = 1
    end


    @last_page = @movies_count / 30

  end

  erb :'movies/index'
end

get '/movies/:id' do
  @id = params[:id]


  db_connection do |connection|

    @movie_info = connection.exec_params("SELECT movies.title, genres.name AS
    genre, studios.name AS studio, actors.name AS actor, cast_members.character,
    movies.rating, movies.year, actors.id AS actor_id
    FROM movies
    LEFT OUTER JOIN genres ON genres.id=movies.genre_id
    LEFT OUTER JOIN studios ON studios.id=movies.studio_id
    LEFT OUTER JOIN cast_members ON cast_members.movie_id=movies.id
    LEFT OUTER JOIN actors ON cast_members.actor_id=actors.id
    WHERE movies.id=$1
    ORDER BY actors.name", [@id])
  end

  erb :'movies/show'
end
