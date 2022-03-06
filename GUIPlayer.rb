# Credit to the lab material and lecture material as it provided a lot of the frameowrk for this.
# Much of the code was walked through during lectures and labs.

require './input_functions'
require 'rubygems'
require 'gosu'
# Havn't used TK
#require 'tk'


# Colours for the program
LEFT_COLOUR = Gosu::Color.new(0xff_0000ff)
RIGHT_COLOUR = Gosu::Color.new(0xFF000000)
TEXT_COLOUR = Gosu::Color.new(0xff_ffffff)

# Ordering
module ZOrder
    BACKGROUND, MIDDLE, TOP, GUI = *0..3
end

class Circle
    attr_reader :columns, :rows
  
    def initialize(radius)
      @columns = @rows = radius * 2
  
      clear, solid = 0x00.chr, 0xff.chr
  
      lower_half = (0...radius).map do |y|
        x = Math.sqrt(radius ** 2 - y ** 2).round
        right_half = "#{solid * x}#{clear * (radius - x)}"
        right_half.reverse + right_half
      end.join
      alpha_channel = lower_half.reverse + lower_half
      # Expand alpha bytes into RGBA color values.
      @blob = alpha_channel.gsub(/./) { |alpha| solid * 3 + alpha }
    end
  
    def to_blob
      @blob
    end
end

# Bitmaps for the Album artwork
class Artwork
	attr_accessor :bmp
	def initialize (file)
		@bmp = Gosu::Image.new(file)
	end
end

class Track
  attr_accessor :track_key, :name, :location
    def initialize (track_key, name, location)
      @track_key = track_key
      @name = name
      @location = location
    end
end

class Album
  attr_accessor :primary_key, :title, :artist,:artwork, :genre, :tracks
  def initialize (primary_key, title, artist,artwork, genre, tracks)
    @primary_key = primary_key
    @title = title
	@artist = artist
	@artwork = artwork
    @genre = genre
    @tracks = tracks
   end
end

class Song
	attr_accessor :song
	def initialize (file)
		@song = Gosu::Song.new(file)
	end
end

class MusicPlayer < Gosu::Window

WIDTH = 1000
HEIGHT = 600
def initialize
    super(WIDTH, HEIGHT)
		self.caption = "Terry's Music Player"
		@locs = [60,60]
		@album_font_tracks = Gosu::Font.new(30)
		@debug_font = Gosu::Font.new(20)
		@album = 0
		@track = 0

		@an_x = 585
        @an_y = 455
        @start_pos = 585
        @end_pos = 975
        @speed = 0

		@button_play = Gosu::Image.new("./Media/play.png")
		@button_pause = Gosu::Image.new("./Media/pause.png")
		@button_stop = Gosu::Image.new("./Media/stop.png")
		@button_next = Gosu::Image.new("./Media/next.png")

		@circle = Gosu::Image.new(Circle.new(40))
end

def load_album()
	def read_track (music_file, i)
		track_key = i
		track_name = music_file.gets
		track_location = music_file.gets.chomp
		track = Track.new(track_key, track_name, track_location)
		return track
	end

	def read_tracks music_file
		count = music_file.gets.to_i
		tracks = Array.new()
		i = 0
		while i < count
			track = read_track(music_file, i + 1)
			tracks << track
			i += 1
		end
		tracks
	end

	def read_album(music_file, i)
		album_pri_key = i
		album_title = music_file.gets.chomp
		album_artist = music_file.gets
		album_artwork = music_file.gets.chomp
		album_genre = music_file.gets.to_i
		album_tracks = read_tracks(music_file)
		album = Album.new(album_pri_key, album_title, album_artist,album_artwork, album_genre, album_tracks)
		return album
	end

	def read_albums(music_file)
		count = music_file.gets.to_i
		albums = Array.new()
		i = 0
		while i < count
			album = read_album(music_file, i + 1)
			albums << album
			i += 1
		end
	return albums
	end

	music_file = File.new("input.txt", "r")
	albums = read_albums(music_file)
	return albums
end

def draw_albums(albums)
	@bmp = Gosu::Image.new(albums[0].artwork)
	@bmp.draw(0, 0 , z = ZOrder::MIDDLE)
	@bmp = Gosu::Image.new(albums[1].artwork)
	@bmp.draw(0, 300, z = ZOrder::MIDDLE)
	@bmp = Gosu::Image.new(albums[2].artwork)
	@bmp.draw(300, 0 , z = ZOrder::MIDDLE)
	@bmp = Gosu::Image.new(albums[3].artwork)
	@bmp.draw(300, 300, z = ZOrder::MIDDLE)
end

def draw_button()
	@button_play.draw(570, 460, z = ZOrder::TOP)
	@button_pause.draw(670, 460, z = ZOrder::TOP)
	@button_stop.draw(770, 460, z = ZOrder::TOP)
	@button_next.draw(870, 460, z = ZOrder::TOP)
end

def draw_background()
	draw_quad(0,0, LEFT_COLOUR, 0, 800, LEFT_COLOUR, 1000, 0, RIGHT_COLOUR, 1000, 800, RIGHT_COLOUR, z = ZOrder::BACKGROUND)
end

def draw_start(albums)
	draw_albums(albums)
	draw_button()
	draw_background()
end

def draw
	i = 0
	x = 600
	y = 0
	albums = load_album()
	draw_start(albums)

	pointers()
	button_animation()
	
	@debug_font.draw("Mouse X: #{@locs[0]}", 886, 10, ZOrder::TOP)
    @debug_font.draw("Mouse y: #{@locs[1]}", 886, 30, ZOrder::TOP)
	
	if(@album > 0)
		while i < albums[@album-1].tracks.length
			@album_font_tracks.draw("#{albums[@album-1].tracks[i].name}", x , y += 50, ZOrder::TOP, 1.0, 1.0, TEXT_COLOUR)
			if (albums[@album-1].tracks[i].track_key == @track)
				@album_font_tracks.draw("#", x - 20 , y, ZOrder::TOP, 1.0, 1.0, TEXT_COLOUR)
			end
			i+=1
		end
	end
end

def playTrack(track, album)
	albums = load_album()
	i = 0
	j = 0
	while i < albums.length
		if (albums[i].primary_key == album)
			tracks = albums[i].tracks
			while j < tracks.length
				if (tracks[j].track_key == track)
					@song = Gosu::Song.new(tracks[j].location)
						@song.play(false)
				end
				j += 1
			end
		end
		i += 1
	end
end

def update()
	if (@song)
		if (!@song.playing?)
			@track += 1
		end
	end
	@locs = [mouse_x, mouse_y]

end

def needs_cursor?
    true
end

def selectTrack()
	if ((mouse_x > 600 && mouse_x < 880)&& (mouse_y > 50 && mouse_y < 80 ))
		@track = 1
	end
	if ((mouse_x > 600 && mouse_x < 880)&& (mouse_y > 100 && mouse_y < 130 ))
		@track = 2
	end
	if ((mouse_x > 600 && mouse_x < 880)&& (mouse_y > 150 && mouse_y < 180 ))
		@track = 3
	end
	if ((mouse_x > 600 && mouse_x < 880)&& (mouse_y > 200 && mouse_y < 230 ))
		@track = 4
	end
end

def area_clicked(mouse_x, mouse_y)
	if ((mouse_x >0 && mouse_x < 256)&& (mouse_y > 0 && mouse_y < 256 ))
		@album = 1
		@track = 0
	end
	
	if ((mouse_x > 0 && mouse_x < 256) && (mouse_y > 300 && mouse_y <556))
		@album = 2
		@track = 0
	end
	
	if ((mouse_x > 300 && mouse_x < 556) && (mouse_y > 0 && mouse_y <256))
		@album = 3
		@track = 0
	end
	
	if ((mouse_x > 300 && mouse_x < 556) && (mouse_y > 300 && mouse_y <556))
		@album = 4
		@track = 0
	end
	
	if ((mouse_x > 790 && mouse_x < 878)&& (mouse_y > 485 && mouse_y < 562 ))
		@song.stop
		@track = 0
	end
	
	if ((mouse_x > 590 && mouse_x < 678)&& (mouse_y > 485 && mouse_y < 562 ))
		if (@track == nil)
			@track += 1
		end
		@song.play
	end
	
	if ((mouse_x > 690 && mouse_x < 778)&& (mouse_y > 485 && mouse_y < 562 ))
		@song.pause
	end
	
	if ((mouse_x > 890 && mouse_x < 978)&& (mouse_y > 485 && mouse_y < 562 ))
		if (@track == nil)
			@track = 1
		else
			@track += 1
		end
	end
	selectTrack()
	playTrack(@track, @album)
end

def pointers()
	marker_x_1 = 40
	marker_y_1 = 20
	marker_x_2 = 20
	marker_y_2 = 50
	marker_x_3 = 60
	marker_y_3 = 50
	if (@album == 1)
		Gosu.draw_triangle(marker_x_1, marker_y_1, Gosu::Color::RED, marker_x_2, marker_y_2, Gosu::Color::GREEN, marker_x_3, marker_y_3, Gosu::Color::BLUE, ZOrder::GUI, mode=:default)
	end
	if (@album == 2)
		Gosu.draw_triangle(marker_x_1, marker_y_1 + 300, Gosu::Color::RED, marker_x_2, marker_y_2 + 300, Gosu::Color::GREEN, marker_x_3, marker_y_3 + 300, Gosu::Color::BLUE, ZOrder::GUI, mode=:default)
	end
	if (@album == 3)
		Gosu.draw_triangle(marker_x_1 + 300, marker_y_1, Gosu::Color::RED, marker_x_2 + 300, marker_y_2, Gosu::Color::GREEN, marker_x_3 + 300, marker_y_3, Gosu::Color::BLUE, ZOrder::GUI, mode=:default)
	end
	if (@album == 4)
		Gosu.draw_triangle(marker_x_1 + 300, marker_y_1 + 300, Gosu::Color::RED, marker_x_2 + 300, marker_y_2 + 300, Gosu::Color::GREEN, marker_x_3 + 300, marker_y_3 + 300, Gosu::Color::BLUE, ZOrder::GUI, mode=:default)
	end
end
def button_animation
	if ((mouse_x > 595 && mouse_x < 670) && (mouse_y > 507 && mouse_y < 577))
		@circle.draw(592, 487, ZOrder::TOP, 1.0, 1.0,  0x64_ff0000)
	end
	if ((mouse_x > 698 && mouse_x < 769) && (mouse_y > 507 && mouse_y < 577))
		@circle.draw(695, 487, ZOrder::TOP, 1.0, 1.0, 0x64_ff0000)
	end
	if ((mouse_x > 794 && mouse_x < 870) && (mouse_y > 507 && mouse_y < 577))
		@circle.draw(791, 487, ZOrder::TOP, 1.0, 1.0,  0x64_ff0000)
	end
	if ((mouse_x > 897 && mouse_x < 967) && (mouse_y > 507 && mouse_y < 577))
		@circle.draw(894, 487, ZOrder::TOP, 1.0, 1.0,  0x64_ff0000)
	end
end

def button_down(id)
	case id
		when Gosu::MsLeft
			@locs = [mouse_x, mouse_y]
			area_clicked(mouse_x, mouse_y)
    end
end

end

MusicPlayer.new.show