import re
import shutil


LocalizableFilePath = "./LightComicsV2/Resources/Strings/ko.lproj/Localizable.strings"
tempFilePath = "./tempI18N.swift"
I18NSwiftFilePath = "./LightComicsV2/Resources/Strings/I18N.swift"

class LocalizeInfo:
    def __init__(self, _key, _value, _desc):
        self._key = _key
        self._value = _value
        self._desc = _desc


localizableFile = open(LocalizableFilePath, "r")
localizableStrings = localizableFile.read()
localizableStrings = localizableStrings.replace(";", "")
localizableStringsLines = localizableStrings.splitlines()

convertedLocalizables = []

for localizableString in localizableStringsLines:
    if localizableString == '':
        continue
    if localizableString.startswith("#"):
        continue

    _key = localizableString.split("=")[0].strip().replace('"', "")
    _value = localizableString.split("=")[1].strip().replace('"', "")
    _desc = "/// " + _value

    if _key == '':
        continue

    info = LocalizeInfo(_key, _value, _desc)
    convertedLocalizables.append(info)


temp = open(tempFilePath, "w")
temp.write("extension R {\n")
temp.write("\tstruct string {\n")
for convertedLocalizableInfo in convertedLocalizables:
    temp.writelines(["\t\t", convertedLocalizableInfo._desc, "\n"])
    line = f'\t\tstatic let {convertedLocalizableInfo._key} = "{convertedLocalizableInfo._key}".localized'
    temp.writelines([line, "\n\n"])
temp.write("\t}\n")
temp.write("}\n")

temp.close()
localizableFile.close()
shutil.move(tempFilePath, I18NSwiftFilePath)
