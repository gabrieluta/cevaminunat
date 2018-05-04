from pydrive.auth import GoogleAuth
from pydrive.drive import GoogleDrive
from os import walk

gauth = GoogleAuth()
drive = GoogleDrive(gauth)

file_list = drive.ListFile({'q': "'root' in parents and trashed=false"}).GetList()
for file in file_list:
  if file['title'] == 'train_data':
    train_folder = drive.ListFile({'q': "'%s' in parents and trashed=false" % str(file['id'])}).GetList()

print(list(train_folder))


# f = []
# path = "/Users/gabrielad/Desktop/train/"
# for (dirpath, dirnames, filenames) in walk(path):
#     f.extend(filenames)
#     break
# f.remove('.DS_Store')
#
# for imagepath in f:
#     image_file = drive.CreateFile({'title': imagepath, "parents": [{"kind": "drive#fileLink","id": folder_id}]})
#     image_file.SetContentFile(path+imagepath)
#     image_file.Upload()


