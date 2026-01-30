defmodule MrMimeTest do
  use ExUnit.Case
  doctest MrMIME

  test "mr mime file format recognition" do
    {:ok, "application/pdf"} =
      MrMIME.filetype("./test/files/mime/test.pdf")

    {:ok, "application/java-archive"} =
      MrMIME.filetype("./test/files/mime/test.jar")

    {:ok, "application/zip"} =
      MrMIME.filetype("./test/files/mime/test.zip")

    {:ok, "application/vnd.rar"} =
      MrMIME.filetype("./test/files/mime/test.rar")

    {:ok, "video/mp4"} =
      MrMIME.filetype("./test/files/mime/test.mp4")

    {:ok, "video/avi"} =
      MrMIME.filetype("./test/files/mime/test.avi")

    {:ok, "video/webm"} =
      MrMIME.filetype("./test/files/mime/test.webm")

    {:ok, "image/png"} =
      MrMIME.filetype("./test/files/mime/test.png")

    {:ok, "image/apng"} =
      MrMIME.filetype("./test/files/mime/test.apng")

    {:ok, "image/gif"} =
      MrMIME.filetype("./test/files/mime/test.gif")

    {:ok, "image/webp"} =
      MrMIME.filetype("./test/files/mime/test.webp")

    {:ok, "application/x-7z-compressed"} =
      MrMIME.filetype("./test/files/mime/test.7z")

    {:ok, "application/msword"} =
      MrMIME.filetype("./test/files/mime/test.doc")

    {:ok, "application/vnd.ms-powerpoint"} =
      MrMIME.filetype("./test/files/mime/test.ppt")

    {:ok, "application/vnd.ms-excel"} =
      MrMIME.filetype("./test/files/mime/test.xls")

    {:ok, "application/vnd.openxmlformats-officedocument.wordprocessingml.document"} =
      MrMIME.filetype("./test/files/mime/test.docx")

    {:ok, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"} =
      MrMIME.filetype("./test/files/mime/test.xlsx")

    {:ok, "application/vnd.openxmlformats-officedocument.presentationml.presentation"} =
      MrMIME.filetype("./test/files/mime/test.pptx")

    {:ok, "application/x-ms-msg"} =
      MrMIME.filetype("./test/files/mime/test.msg")

    {:ok, "message/rfc822"} =
      MrMIME.filetype("./test/files/mime/test.eml")
  end
end
