#!/usr/bin/env ruby

require 'optparse'

def show_errors(name,type,errors)
  if errors.match /\S/
    puts "Differences found in #{type} test for #{name}: -reference, +ours"
    puts errors
  else
    puts "#{name} passes #{type} test"
  end
end

# temporary file names
ours_run = 'ours.runout'
ours_dis = 'ours.disasm'

cls = '*'

OptionParser.new do |opts|
  opts.banner = "Usage: run_tests.rb [disasm|runner] [options]"

  opts.on('-c', '--class [classname]', 'Run a specific case') do |c|
    cls = c
  end

  opts.on('-h', '--help', 'Display this message') do
    puts opts
    exit
  end
end.parse!

# Usage: 'disasm' or 'runner' to run each type of test, no args to run both
run_disasm = (ARGV[0] == 'disasm' or ARGV[0].nil?)
run_runner = (ARGV[0] == 'runner' or ARGV[0].nil?)

here_dir = "#{Dir.pwd}/#{File.dirname($0)}"
test_dir = "#{here_dir}/../test"
`make all` # build the reference *.disasm,*.runout from the real jvm
Dir.glob("#{test_dir}/#{cls}.java") do |src|
  name = src.match(/(\w+)\.java/)[1]
  if run_disasm
    # compare disas output
    `#{here_dir}/../console/disassembler.coffee #{test_dir}/#{name}.class >#{ours_dis}`
    show_errors(name,'disasm',`#{here_dir}/cleandiff.sh #{test_dir}/#{name}.disasm #{ours_dis}`)
  end
  if run_runner
    # compare runtime output
    `#{here_dir}/../console/runner.coffee #{test_dir}/#{name}.class --log=error 2>&1 >#{ours_run}`
    show_errors(name,'runtime',`diff -U0 #{test_dir}/#{name}.runout #{ours_run} | sed '1,2d'`)
  end
end

File.unlink ours_dis if File.exists? ours_dis
File.unlink ours_run if File.exists? ours_run
