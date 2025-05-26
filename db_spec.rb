describe 'database' do
    before do
        `rm -rf test.db`
    end
  def run_script(commands)
    raw_output = nil
    IO.popen("./main test.db", "r+") do |pipe|
      commands.each { |command| pipe.puts command }
      pipe.close_write
      raw_output = pipe.read
    end
    raw_output.split("\n")
  end

  it 'inserts and retrieves a row' do
    result = run_script([
      "insert 1 user user@example.com",
      "select",
      ".exit",
    ])

    expect(result).to eq([
      "SimpleSQL > Executed.",
      "SimpleSQL > (1, user, user@example.com)",
      "Executed.",
      "SimpleSQL > "
    ])
  end

  it 'prints error message when table is full' do
    script = (1..2000).map do |i|
      "insert #{i} user#{i} person#{i}@example.com"
    end
    script << ".exit"
    result = run_script(script)

    expect(result).to include("SimpleSQL > Error: Table Full.")
  end

  it 'allows inserting strings that are the max length' do
    l_username = "a" * 32
    l_email = "a" * 255
    result = run_script([
      "insert 1 #{l_username} #{l_email}",
      "select",
      ".exit",
    ])

    expect(result).to match_array([
      "SimpleSQL > Executed.",
      "SimpleSQL > (1, #{l_username}, #{l_email})",
      "Executed.",
      "SimpleSQL > ",
    ])
  end
  it 'prints error message if strings are too long' do
    long_username = "a"*33
    long_email = "a"*256
    script = [
      "insert 1 #{long_username} #{long_email}",
      "select",
      ".exit",
    ]
    result = run_script(script)
    expect(result).to match_array([
      "SimpleSQL > String is too long.",
      "SimpleSQL > Executed.",
      "SimpleSQL > ",
    ])
  end
  it 'prints an error message if id is negative' do
    script = [
      "insert -1 cstack foo@bar.com",
      "select",
      ".exit",
    ]
    result = run_script(script)
    expect(result).to match_array([
      "SimpleSQL > ID must be positive.",
      "SimpleSQL > Executed.",
      "SimpleSQL > ",
    ])
  end

  it 'keeps data after closing connection' do
    result1 = run_script([
      "insert 1 user1 person1@example.com",
      ".exit",
    ])
    expect(result1).to match_array([
      "SimpleSQL > Executed.",
      "SimpleSQL > ",
    ])
    result2 = run_script([
      "select",
      ".exit",
    ])
    expect(result2).to match_array([
      "SimpleSQL > (1, user1, person1@example.com)",
      "Executed.",
      "SimpleSQL > ",
    ])
  end


end
