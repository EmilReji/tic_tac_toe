class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # columns
                  [[1, 5, 9], [3, 5, 7]]              # diagonals

  attr_reader :squares

  def initialize
    @squares = {}
    reset
  end

  def threat_key(opponent_marker)
    unmarked_keys.each do |unmarked_key|
      possible_threat_arrays = WINNING_LINES.select do |threat_array|
        threat_array.include?(unmarked_key)
      end

      possible_threat_arrays.each do |threat_array|
        markers = threat_array.map { |key| squares[key].marker }
        two_marks = markers.count(opponent_marker) == 2
        one_empty = markers.count(Square::INITIAL_MARKER) == 1
        return unmarked_key if  two_marks && one_empty
      end
    end
    false
  end

  def win_key(my_marker)
    unmarked_keys.each do |unmarked_key|
      possible_win_arrays = WINNING_LINES.select do |win_array|
        win_array.include?(unmarked_key)
      end

      possible_win_arrays.each do |win_array|
        markers = win_array.map { |key| squares[key].marker }
        two_marks = markers.count(my_marker) == 2
        one_empty = markers.count(Square::INITIAL_MARKER) == 1
        return unmarked_key if  two_marks && one_empty
      end
    end
    false
  end

  def []=(key, marker)
    squares[key].marker = marker
  end

  def unmarked_keys
    squares.keys.select { |key| squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def marker_is_winner?(squares)
    markers = squares.collect(&:marker)
    markers.uniq.length == 1 && !markers.include?(Square::INITIAL_MARKER)
  end

  def winning_marker
    WINNING_LINES.each do |line|
      if marker_is_winner?(@squares.values_at(*line))
        return @squares.values_at(*line)[0].marker
      end
    end
    nil
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  # rubocop:disable Metrics/AbcSize
  def draw
    puts "     |     |"
    puts "  #{squares[1]}  |  #{squares[2]}  |  #{squares[3]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{squares[4]}  |  #{squares[5]}  |  #{squares[6]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{squares[7]}  |  #{squares[8]}  |  #{squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/AbcSize
end

class Square
  INITIAL_MARKER = " "

  attr_accessor :marker

  def initialize(marker = INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end
end

class Player
  attr_accessor :marker, :score, :name

  def initialize(marker)
    @marker = marker
    @score = 0
    @name
  end
end

class TTTGame
  FIRST_TO_MOVE = nil
  WINNER_SCORE = 3

  attr_reader :board, :human, :computer

  def initialize
    @board = Board.new
    @human = Player.new(nil)
    @computer = Player.new(nil)
    @current_marker = FIRST_TO_MOVE
  end

  def play
    display_welcome_message
    set_info
    loop do
      display_board
      play_round
      display_result
      break if someone_won_game?
      break unless play_again?
      display_play_again_message
    end
    display_final_result
    display_goodbye_message
  end

  private

  def play_round
    loop do
      current_player_moves
      update_score if board.someone_won?
      break if board.someone_won? || board.full?
      clear_screen_and_display_board if human_turn?
    end
  end

  def set_info
    set_human_marker
    set_computer_marker
    set_human_name
    set_computer_name
  end

  def set_human_marker
    choice = nil
    loop do
      puts "What single-character marker would you like to use?"
      choice = gets.chomp.strip
      break if choice.length == 1
      puts "That is not a possible choice. Please try again."
    end
    human.marker = choice
  end

  def set_computer_marker
    choice = nil
    loop do
      puts "What single-character marker would you like the computer to use?"
      choice = gets.chomp.strip
      break if choice.length == 1 && choice != human.marker
      puts "That is not a possible choice. Please try again."
    end
    computer.marker = choice
  end

  def set_human_name
    choice = nil
    loop do
      puts "What name would you like to use?"
      choice = gets.chomp
      break if !choice.strip.empty?
      puts "That is not valid. Please try again"
    end
    human.name = choice
  end

  def set_computer_name
    choice = nil
    loop do
      puts "What name would you like the computer to use?"
      choice = gets.chomp
      break if !choice.strip.empty? && choice != human.name
      puts "That is not valid. Please try again"
    end
    computer.name = choice
  end

  def display_welcome_message
    clear
    puts "Welcome to Tic Tac Toe!"
    puts "It takes #{WINNER_SCORE} round wins to win the game."
    puts ''
  end

  def display_goodbye_message
    puts "Thanks for playing Tic Tac Toe! Goodbye!"
  end

  def clear
    system 'clear'
  end

  def display_board
    puts "#{human.name} you're a #{human.marker}."
    puts "#{computer.name} is a #{computer.marker}."
    puts ""
    board.draw
    puts ""
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def joinor(values, seperator = ',', final_seperator = 'or')
    if values.length == 1
      values[0].to_s
    elsif values.length == 2
      values.join(" #{final_seperator} ")
    else
      final_val = seperator.to_s + " "
      final_val += final_seperator.to_s + " " + values[-1].to_s
      values[0..-2].join("#{seperator} ") + final_val
    end
  end

  def human_moves
    puts "Choose a square (#{joinor(board.unmarked_keys)}):"
    square = nil
    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      puts "Sorry, that's not a valid choice."
    end

    board[square] = human.marker
  end

  def computer_moves
    marker = computer.marker
    offense = board.win_key(marker)
    defense = board.threat_key(human.marker)
    unmarked_keys = board.unmarked_keys.to_a

    if unmarked_keys.include?(5)
      board[5] = marker
    elsif offense
      board[offense] = marker
    elsif defense
      board[defense] = marker
    else
      board[unmarked_keys.sample] = marker
    end
  end

  def human_turn?
    @current_marker == human.marker
  end

  def computer_turn?
    @current_marker == computer.marker
  end

  def current_player_moves
    if human_turn?
      human_moves
      @current_marker = computer.marker
    elsif computer_turn?
      computer_moves
      @current_marker = human.marker
    else
      choose_who_moves
    end
  end

  def choose_who_moves
    choice = nil
    clear
    loop do
      puts "Pick who you would like go first #{human.name}/#{computer.name}:"
      choice = gets.chomp
      break if choice == human.name || choice == computer.name
      puts "Your choice is invalid. Please try again."
    end
    custom_choice(choice)
  end

  def custom_choice(choice)
    if choice == human.name
      @current_marker = human.marker
    elsif choice == computer.name
      @current_marker = computer.marker
    end
  end

  def display_result
    display_board
    case board.winning_marker
    when human.marker
      puts "#{human.name} won this round!"
    when computer.marker
      puts "#{computer.name} won this round!"
    else
      puts "It's a tie this round!"
    end
    display_score
    puts ""
  end

  def display_score
    puts "#{human.name} have won #{human.score} times."
    puts "#{computer.name} has won #{computer.score} times."
  end

  def display_final_result
    if human.score >= WINNER_SCORE
      puts "#{human.name} have won the entire game."
    elsif computer.score >= WINNER_SCORE
      puts "#{computer.name} has won the entire game."
    end
  end

  def someone_won_game?
    human.score >= WINNER_SCORE || computer.score >= WINNER_SCORE
  end

  def play_again?
    answer = nil
    loop do
      puts "You have not reached the winning score of #{WINNER_SCORE} yet."
      puts "Would you like to continue playing? (y/n)"
      answer = gets.chomp.downcase
      break if %w(y n).include? answer
      puts "Sorry, must be y or n."
    end

    return false if answer == 'n'
    return true if answer == 'y'
  end

  def display_play_again_message
    reset
    puts "Lets play again!"
    puts ""
  end

  def reset
    board.reset
    @current_marker = FIRST_TO_MOVE
    clear
  end

  def update_score
    case board.winning_marker
    when human.marker
      human.score += 1
    when computer.marker
      computer.score += 1
    end
  end
end

game = TTTGame.new
game.play
