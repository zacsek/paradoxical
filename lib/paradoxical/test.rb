$LOAD_PATH.unshift('.')
require 'paradoxical'
#v2 = "/home/zacsek/.PlayOnLinux/wineprefix/Steam/drive_c/Steam/steamapps/common/Victoria 2/history/**/*.txt"
v2 = "/home/zacsek/.PlayOnLinux/wineprefix/Steam/drive_c/Steam/steamapps/common/Victoria 2/common/**/*.txt"

Dir[v2].each do |f|
  Paradoxical.parse(f)
end

