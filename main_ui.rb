require 'gosu'
require_relative 'controller'
require_relative 'ai1_player'
require_relative 'human_player'

class UIStone
  attr_reader :coord_x, :coord_y, :idx_x, :idx_y
  attr_accessor :color

  def initialize window, coord_x, coord_y, idx_x, idx_y, stone_size, color = :free
    @coord_x = coord_x
    @coord_y = coord_y
    @stone_size = stone_size
    @color = color
    @idx_x = idx_x
    @idx_y = idx_y
  end
end

class Board
  attr_reader :grid

  def initialize window, top_x, top_y, cell_size, stone_size, num_cell=9
    @stone_size = stone_size
    @white = Gosu::Image.new(window, "img/white_circle.png", true)
    @black = Gosu::Image.new(window, "img/black_circle.png", true)
    @grid = []
    (0..num_cell).each do |x|
      @grid[x] = []
      (0..num_cell).each do |y|
        coord_x = top_x + x * cell_size
        coord_y = top_y + y * cell_size
        @grid[x] << UIStone.new(window, coord_x, coord_y, x, y, stone_size)
      end
    end
  end

  def draw(goban)
    (0..goban.size).each do |i|
      (0..goban.size).each do |j|
        stone = goban.stone_at?(i+1, j+1)
        if stone and stone.color != -1
            cell = @grid[i][j]
          if goban.color_name(stone.color) == "black"
            @white.draw(cell.coord_x - @stone_size / 2, cell.coord_y - @stone_size / 2, 0)
          else
            @black.draw(cell.coord_x - @stone_size / 2, cell.coord_y - @stone_size / 2, 0)
          end
        end
      end
    end
  end
end

class GoWindow < Gosu::Window

  BACKGROUND_COLOR = Gosu::Color.new(0xFFD3D3D3)
  WIDTH = 800
  HEIGHT = 800
  CELL_SIZE = 40
  STONE_SIZE = 25
  GOBAN_SIZE = 9
  GRID_SIZE = (GOBAN_SIZE-1) * CELL_SIZE
  OFFSET = 70

  def initialize
    super 600, 600, false
    self.caption = "Rubigolo"
    @board = Board.new(self, OFFSET, OFFSET, CELL_SIZE, STONE_SIZE)

    @controller = Controller.new
    @controller.new_game(GOBAN_SIZE, 2, 0)
    @controller.set_player(HumanPlayer.new(@controller, 0))
    @controller.set_player(Ai1Player.new(@controller, 1))

    $log.level = Logger::ERROR
  end

  def update
    @controller.let_ai_play unless @controller.next_player_is_human?
  end

  def draw
    draw_background
    draw_grid
    @board.draw(@controller.goban)
  end

  def button_down(id)
    case id
    when Gosu::MsLeft
      cells = @board.grid.flatten.select{ |c| (c.coord_x - mouse_x).abs < 5 && (c.coord_y - mouse_y).abs < 5}
      move = parse_index(cells[0]) if cells and cells.size == 1
      begin
        @controller.play_one_move(move) if move
      rescue Exception => e
        $log.error(e.message)
      end
    when Gosu::KbP
      @controller.play_one_move("pass")
    end
  end

  def needs_cursor?; true; end

  private
  def draw_background
    draw_quad(0, 0, BACKGROUND_COLOR,
                          WIDTH, 0, BACKGROUND_COLOR,
                          0, HEIGHT, BACKGROUND_COLOR,
                          WIDTH, HEIGHT, BACKGROUND_COLOR,
                          0)
  end

  def draw_grid
    (GOBAN_SIZE).times do |i|
      draw_line(i * CELL_SIZE + OFFSET, OFFSET, Gosu::Color::BLACK,
                        i * CELL_SIZE + OFFSET, GRID_SIZE + OFFSET, Gosu::Color::BLACK)
      draw_line(OFFSET, i * CELL_SIZE + OFFSET, Gosu::Color::BLACK,
                        GRID_SIZE + OFFSET, i * CELL_SIZE + OFFSET, Gosu::Color::BLACK)
    end
  end

  def parse_index(c)
     ('a'.ord + c.idx_x).chr + (c.idx_y + 1).to_s
  end

end

GoWindow.new.show
