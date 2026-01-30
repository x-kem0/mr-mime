defmodule MrMIME do
  @moduledoc """
  Uses 'magic numbers' to identify binary data and provides extension -> MIME type conversion
  Refer to source code for supported types.
  """
  alias MrMIME.Extensions

  # Refer to the following for reference:
  # https://www.iana.org/assignments/media-types/media-types.xhtml
  # https://www.garykessler.net/library/file_sigs_GCK_latest.html
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/MIME_types/Common_types
  # https://en.wikipedia.org/wiki/List_of_file_signatures
  #
  # webm and mkv are treated as video/webm

  @doc """
  Attempt to convert a given filepath or extension to a MIME type.

  Returns `{:ok, type}` or `{:error, :unknown}`
  """
  def identify_filename(filepath) do
    ext = filepath |> Path.extname() |> String.downcase()
    Extensions.get_by_ext(ext)
  end

  @doc """
  Attempt to identify a binary based off of known signatures.

  Returns `{:ok, type}` or `{:error, :unknown}`
  """
  def identify_bytes(bytes) do
    identify_bytes_with_name(bytes)
  end

  @doc """
  Reads a file from disk and attempts to identify it.
  Uses magic numbers for first-attempt and falls back to extension-based identification.

  Returns `{:ok, type}` or `{:error, :unknown}`
  """
  def filetype(filepath) do
    with {:ok, bytes} <- File.read(filepath) do
      identify_bytes_with_name(bytes, filepath)
    end
  end

  @doc """
  Attempt to identify a binary based off of known signatures. If that fails, uses the provided
  filename to map to a MIME type.
  Given that many filetypes are repackaged .zips and such, it is best
  to use this method if you have any filename information available.

  Returns `{:ok, type}` or `{:error, :unknown}`
  """
  def identify_bytes_with_name(bytes, filename \\ "") do
    ext = filename |> Path.extname() |> String.downcase()

    case identify_signature(bytes) do
      nil ->
        Extensions.get_by_ext(ext)

      :maybezip ->
        {:ok, identify_zip_subtype(ext)}

      :maybepng ->
        {:ok, identify_png_subtype(ext)}

      :ooxml ->
        {:ok, identify_ooxml_subtype(ext)}

      :docfile ->
        sig = String.slice(bytes, 510, 24)

        case identify_ms_docfile_subtype(sig, ext) do
          {:ok, _} = result -> result
          {:error, _} = err -> err
          type -> {:ok, type}
        end

      type ->
        {:ok, type}
    end
  end

  # --------------------------------------------------------------------------------------------------------------------------
  # Subtypes
  # --------------------------------------------------------------------------------------------------------------------------

  @ms_docfile_subheader_ppt_alt_1 <<0x0F, 0x00, 0xE8, 0x03>>
  @ms_docfile_subheader_ppt_alt_2 <<0xA0, 0x46, 0x1D, 0xF0>>
  @ms_docfile_subheader_ppt_alt_3_part_1 <<0xFD, 0xFF, 0xFF, 0xFF>>
  @ms_docfile_subheader_ppt_alt_3_part_2 <<0x00, 0x00>>

  @ms_docfile_subheader_doc <<0xEC, 0xA5, 0xC1, 0x00>>

  @ms_docfile_subheader_xls_alt_1 <<0x09, 0x08, 0x10, 0x00, 0x00, 0x06, 0x05, 0x00>>
  @ms_docfile_subheader_xls_alt_2_part_1 <<0xFD, 0xFF, 0xFF, 0xFF>>
  @ms_docfile_subheader_xls_alt_2_part_2_alt_1 <<0x00>>
  @ms_docfile_subheader_xls_alt_2_part_2_alt_2 <<0x02>>
  @ms_docfile_subheader_xls_alt_3 <<0xFD, 0xFF, 0xFF, 0xFF, 0x20, 0x00, 0x00, 0x00>>

  @ms_docfile_subheader_msg_alt_1 <<0x52, 0x00, 0x6F, 0x00, 0x6F, 0x00, 0x74, 0x00, 0x20, 0x00,
                                    0x45, 0x00, 0x6E, 0x00, 0x74, 0x00, 0x72, 0x00, 0x79, 0x00>>
  @ms_docfile_subheader_msg_alt_2 <<0xFD, 0xFF, 0xFF, 0xFF, 0x04>>
  @ms_docfile_subheader_msg_alt_3 <<0xFD, 0xFF, 0xFF, 0xFF, 0x07>>

  # ----------------
  # ms docfile subtypes
  # ----------------

  # doc
  defp identify_ms_docfile_subtype(@ms_docfile_subheader_doc <> _, _name) do
    "application/msword"
  end

  # msg 1
  defp identify_ms_docfile_subtype(@ms_docfile_subheader_msg_alt_3 <> _, _name) do
    "application/x-ms-msg"
  end

  # ppt
  defp identify_ms_docfile_subtype(@ms_docfile_subheader_ppt_alt_1 <> _, _name) do
    "application/vnd.ms-powerpoint"
  end

  defp identify_ms_docfile_subtype(@ms_docfile_subheader_ppt_alt_2 <> _, _name) do
    "application/vnd.ms-powerpoint"
  end

  defp identify_ms_docfile_subtype(
         @ms_docfile_subheader_ppt_alt_3_part_1 <>
           <<_, _>> <> @ms_docfile_subheader_ppt_alt_3_part_2 <> _,
         _name
       ) do
    "application/vnd.ms-powerpoint"
  end

  # xls
  defp identify_ms_docfile_subtype(@ms_docfile_subheader_xls_alt_1 <> _, _name) do
    "application/vnd.ms-excel"
  end

  defp identify_ms_docfile_subtype(
         @ms_docfile_subheader_xls_alt_2_part_1 <>
           <<_>> <> @ms_docfile_subheader_xls_alt_2_part_2_alt_1 <> _,
         _name
       ) do
    "application/vnd.ms-excel"
  end

  defp identify_ms_docfile_subtype(
         @ms_docfile_subheader_xls_alt_2_part_1 <>
           <<_>> <> @ms_docfile_subheader_xls_alt_2_part_2_alt_2 <> _,
         _name
       ) do
    "application/vnd.ms-excel"
  end

  defp identify_ms_docfile_subtype(@ms_docfile_subheader_xls_alt_3 <> _, _name) do
    "application/vnd.ms-excel"
  end

  # msg 2
  defp identify_ms_docfile_subtype(@ms_docfile_subheader_msg_alt_1 <> _, _name) do
    "application/x-ms-msg"
  end

  defp identify_ms_docfile_subtype(@ms_docfile_subheader_msg_alt_2 <> _, _name) do
    "application/x-ms-msg"
  end

  defp identify_ms_docfile_subtype(_bytes, name) do
    Extensions.get_by_ext(name)
  end

  # ----------------
  # ooxml subtypes
  # ----------------

  defp identify_ooxml_subtype(".pptx") do
    "application/vnd.openxmlformats-officedocument.presentationml.presentation"
  end

  defp identify_ooxml_subtype(".xlsx") do
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  defp identify_ooxml_subtype(_) do
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  end

  # ----------------
  # png subtypes
  # ----------------
  defp identify_png_subtype(".apng") do
    "image/apng"
  end

  defp identify_png_subtype(_) do
    "image/png"
  end

  # ----------------
  # zip subtypes
  # ----------------
  defp identify_zip_subtype(".jar") do
    "application/java-archive"
  end

  defp identify_zip_subtype(".odt") do
    "application/vnd.oasis.opendocument.text"
  end

  defp identify_zip_subtype(".odp") do
    "application/vnd.oasis.opendocument.presentation"
  end

  defp identify_zip_subtype(".oxps") do
    "application/vnd.oasis.opendocument.presentation"
  end

  defp identify_zip_subtype(_) do
    "application/zip"
  end

  # --------------------------------------------------------------------------------------------------------------------------
  # Documents
  # --------------------------------------------------------------------------------------------------------------------------
  @signature_pdf <<0x25, 0x50, 0x44, 0x46>>
  @signature_ms_ooxml <<0x50, 0x4B, 0x03, 0x04, 0x14, 0x00, 0x06, 0x00>>
  @signature_ms_docfile <<0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1>>
  @signature_email <<0x46, 0x72, 0x6F, 0x6D, 0x3A, 0x20>>

  defp identify_signature(@signature_pdf <> _) do
    "application/pdf"
  end

  defp identify_signature(@signature_email <> _) do
    "message/rfc822"
  end

  defp identify_signature(@signature_ms_ooxml <> _) do
    :ooxml
  end

  defp identify_signature(@signature_ms_docfile <> _) do
    :docfile
  end

  # --------------------------------------------------------------------------------------------------------------------------
  # Archives
  # --------------------------------------------------------------------------------------------------------------------------
  @signature_zip_alt_1 <<0x50, 0x4B, 0x03, 0x04>>
  @signature_zip_alt_2 <<0x50, 0x4B, 0x05, 0x06>>
  @signature_zip_alt_3 <<0x50, 0x4B, 0x07, 0x08>>
  @signature_rar <<0x52, 0x61, 0x72, 0x21>>
  @signature_7z <<0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C>>

  # :maybezip
  defp identify_signature(@signature_zip_alt_1 <> _) do
    :maybezip
  end

  defp identify_signature(@signature_zip_alt_2 <> _) do
    :maybezip
  end

  defp identify_signature(@signature_zip_alt_3 <> _) do
    :maybezip
  end

  defp identify_signature(@signature_rar <> _) do
    "application/vnd.rar"
  end

  defp identify_signature(@signature_7z <> _) do
    "application/x-7z-compressed"
  end

  # --------------------------------------------------------------------------------------------------------------------------
  # Images
  # --------------------------------------------------------------------------------------------------------------------------
  @signature_bmp <<0x42, 0x4D>>
  @signature_png <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A>>
  @signature_jpg <<0xFF, 0xD8, 0xFF, 0xE0>>

  @signature_gif_alt_1 <<0x47, 0x49, 0x46, 0x38, 0x37, 0x61>>
  @signature_gif_alt_2 <<0x47, 0x49, 0x46, 0x38, 0x39, 0x61>>

  @signature_webp_part_1 <<0x52, 0x49, 0x46, 0x46>>
  @signature_webp_part_2 <<0x57, 0x45, 0x42, 0x50>>

  # image/bmp
  defp identify_signature(@signature_bmp <> _) do
    "image/bmp"
  end

  # image/png
  defp identify_signature(@signature_png <> _) do
    :maybepng
  end

  # image/jpeg
  defp identify_signature(@signature_jpg <> _) do
    "image/jpeg"
  end

  # image/webp
  defp identify_signature(@signature_webp_part_1 <> <<_, _, _, _>> <> @signature_webp_part_2 <> _) do
    "image/webp"
  end

  # image/gif 1
  defp identify_signature(@signature_gif_alt_1 <> _) do
    "image/gif"
  end

  # image/gif 2
  defp identify_signature(@signature_gif_alt_2 <> _) do
    "image/gif"
  end

  # --------------------------------------------------------------------------------------------------------------------------
  # Video
  # --------------------------------------------------------------------------------------------------------------------------
  @signature_webm <<0x1A, 0x45, 0xDF, 0xA3>>
  @signature_mp4_alt_1 <<0x66, 0x74, 0x79, 0x70, 0x4D, 0x53, 0x4E, 0x56>>
  @signature_mp4_alt_2 <<0x66, 0x74, 0x79, 0x70, 0x69, 0x73, 0x6F, 0x6D>>
  @signature_mp4_alt_3 <<0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, 0x6D, 0x70, 0x34, 0x32>>
  @signature_avi_part_1 <<0x52, 0x49, 0x46, 0x46>>
  @signature_avi_part_2 <<0x41, 0x56, 0x49, 0x20>>

  # video/webm
  defp identify_signature(@signature_webm <> _) do
    "video/webm"
  end

  # video/mp4 1
  defp identify_signature(@signature_mp4_alt_1 <> _) do
    "video/mp4"
  end

  # video/mp4 2
  defp identify_signature(@signature_mp4_alt_2 <> _) do
    "video/mp4"
  end

  # video/mp4 3
  defp identify_signature(@signature_mp4_alt_3 <> _) do
    "video/mp4"
  end

  # video/avi
  defp identify_signature(@signature_avi_part_1 <> <<_, _, _, _>> <> @signature_avi_part_2 <> _) do
    "video/avi"
  end

  # unknown
  defp identify_signature(_) do
    nil
  end
end
