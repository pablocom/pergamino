defmodule Mix.Tasks.Setup.Windows do
  use Mix.Task

  @shortdoc "Patches native dependencies for Windows/MinGW compilation"

  @moduledoc """
  Patches native NIF dependencies that don't compile on Windows out of the box.

  Currently patches:
  - `crc32cer` - adds MinGW/Windows case to `rdendian.h` (missing `endian.h`)

  This task is a no-op on non-Windows platforms. Safe to run multiple times.

  ## Prerequisites

  - MinGW-w64 must be installed (`choco install mingw` or `scoop install gcc`)
  - `g++` / `c++` must be available in PATH

  ## Usage

      mix setup.windows
  """

  @crc32cer_header "deps/crc32cer/c_src/rdendian.h"

  @mingw_patch """
  #elif defined(_WIN32) || defined(__MINGW32__) || defined(__MINGW64__)
  #define be64toh(x) __builtin_bswap64(x)
  #define be32toh(x) __builtin_bswap32(x)
  #define be16toh(x) __builtin_bswap16(x)
  #define le16toh(x) (x)
  #define le32toh(x) (x)
  #define le64toh(x) (x)
  """

  @impl Mix.Task
  def run(_args) do
    case :os.type() do
      {:win32, _} ->
        Mix.shell().info("Patching native dependencies for Windows...")
        patch_crc32cer()
        recompile_nifs()
        Mix.shell().info("Windows native dependencies patched successfully!")

      _ ->
        :ok
    end
  end

  defp patch_crc32cer do
    if File.exists?(@crc32cer_header) do
      content = File.read!(@crc32cer_header)

      if String.contains?(content, "__MINGW32__") do
        Mix.shell().info("crc32cer already patched, skipping.")
      else
        patched = String.replace(content, "#else\n #include <endian.h>", @mingw_patch <> "\n#else\n #include <endian.h>")
        File.write!(@crc32cer_header, patched)
        Mix.shell().info("Patched crc32cer rdendian.h for MinGW.")
      end
    else
      Mix.shell().info("crc32cer not found in deps, skipping patch.")
    end
  end

  defp recompile_nifs do
    Mix.shell().info("Recompiling native dependencies...")
    Mix.Task.run("deps.compile", ["crc32cer", "snappyer", "--force"])
  end
end
