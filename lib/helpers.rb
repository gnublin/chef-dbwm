# MIT License
# Copyright (c) 2018 Gauthier FRANCOIS

class Helpers
  def self.real_path(base_path, relative_path)
    File.realpath("#{base_path}/#{relative_path}")
  rescue Errno::ENOENT
    nil
  end

  def self.read_file(file_path)
    File.read(file_path)
  rescue Errno::EACCES
    nil
  end
end
