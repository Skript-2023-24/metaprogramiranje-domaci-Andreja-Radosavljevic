require 'google_drive'

class CustomTable
  include Enumerable

  attr_accessor :spreadsheet, :worksheet, :matrix


  def initialize(key, session)
    if key != nil && session !=nil
      @spreadsheet = session.spreadsheet_by_key(key)
      @worksheet = @spreadsheet.worksheets[0]
      worksheet_to_matrix(@worksheet)
    end
  end

  def worksheet_to_matrix(worksheet)
    matrix = Array.new
    (1..worksheet.num_cols).each do |col|
        column = Array.new
        (1..worksheet.num_rows).each do |row|
            column << worksheet[row, col]
        end

        matrix << column
    end

    @matrix = matrix
  end

  def row(i)
    matrix.transpose[i]
  end

  def each(&block)
    @matrix.transpose.each do |row|

      unless row.any?{ |cell| cell.to_s.downcase.include?('total') || cell.to_s.downcase.include?('subtotal') }
        row.each do |col|
          yield col
        end
      end
    end
  end

  def [](column_name)
    Column.new(matrix.find { |row| row[0] == column_name })

  end

  def method_missing(name, *args, &block)
    column_name = name.to_s
    p @matrix.transpose
    index = @matrix.transpose[0].index(column_name)
    if index
      return Column.new(@matrix[index])
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    kolona = name.to_s
    index = @matrix[0].index(kolona) # Pronalaženje odgovarajućeg indeksa kolone u transponovanoj matrici
    index || super
  end

  def +(other_table)
    raise "Headers are different" unless @matrix.transpose[0] == other_table.matrix.transpose[0]

    result = CustomTable.new('', nil)
    result_matrix = matrix.transpose + other_table.matrix.transpose.drop(1)
    result.matrix = result_matrix.transpose
    result
  end

  def -(other_table)
    raise "Headers are different" unless @matrix.transpose[0] == other_table.matrix.transpose[0]

    raise "Headers are different" unless @matrix.transpose[0] == other_table.matrix.transpose[0]

    result = CustomTable.new('', nil)
    result_matrix = matrix.transpose - other_table.matrix.transpose.drop(1)
    result.matrix = result_matrix.transpose
    result
  end

end

class Column
  include Enumerable
  attr_accessor :kolona

  def initialize(kolona)
    @kolona = kolona
  end

  def each(&block)
    @kolona.each(&block)
  end

  def [](ind)
    @kolona[ind]
  end

  def []=(ind, v)
    @kolona[ind] = v
  end

  def sum
    @kolona.drop(1).map(&:to_i).reduce &:+
  end

  def avg
    sum / (@kolona.length - 1).to_f
  end


end

# Kreiranje Google Drive sesije
session = GoogleDrive::Session.from_config("config.json")

# Kreiranje instance CustomTable sa odgovarajućim ključem za Google Sheets tabelu
a = CustomTable.new("1T1D75g5XclPIj9MY1SIGJZfq-YQQgiSATCAocRnto8c", session)
b = CustomTable.new("111YKJja3WQBQfSwIYt_5OjTwkGw1w6_EW_fVV4ih80o", session)

p "Prikaz matrice"
p a.matrix

p "Prikaz drugog reda"
p a.row(2)

p "Iteriranje kroz sve elemente CustomTable"
a.each do |item|
  p item
end

p "Prikaz celokupne kolone PrvaKolona"
p a["PrvaKolona"].kolona

p "Prikaz prvog elementa u PrvaKolona"
p a["PrvaKolona"][0]

p "Promena vrednosti trećeg elementa u PrvaKolona na 404"
a["PrvaKolona"][3] = 404
p a.matrix

p "Provera sume vrednosti u PrvaKolona (preskočen header)"
p a.PrvaKolona.sum

p "Provera prosečne vrednosti u PrvaKolona (preskočen header)"
p a.PrvaKolona.avg

p "Mapiranje vrednosti u PrvaKolona sa *2 (preskočen header)"
p a["PrvaKolona"].map { |cell| cell * 2 }

p "Selektovanje određenih vrednosti u PrvaKolona (preskočen header)"
p a["PrvaKolona"].select { |cell|  cell == "2"}

p "Sabiranje"
p (a+b).matrix
p "Oduzimanje"
p (a-b).matrix

p a.PrvaKolona.kolona
