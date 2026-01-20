defmodule Mix.Tasks.Setup.Ssl do
  use Mix.Task

  @shortdoc "Generates SSL certificates for local development"

  @moduledoc """
  Generates SSL certificates for local development using mkcert.

  This task:
  - Checks if mkcert is installed
  - Generates certificates for localhost and 10.0.2.2 (Android emulator)
  - Places certificates in server/priv/cert/
  - Copies public certificate to android/app/src/main/res/raw/
  - Is safe to run multiple times

  ## Usage

      mix setup.ssl

  ## Requirements

  - mkcert must be installed and available in PATH
  """

  @cert_dir "priv/cert"
  @cert_file "localhost.pem"
  @key_file "localhost_key.pem"
  @android_cert_dir "../android/app/src/main/res/raw"
  @hosts ["localhost", "10.0.2.2"]

  @impl Mix.Task
  def run(_args) do
    Mix.shell().info("Setting up SSL certificates for local development...")

    with :ok <- check_mkcert_installed(),
         :ok <- ensure_directory(@cert_dir),
         :ok <- generate_certificates(),
         :ok <- copy_to_android() do
      Mix.shell().info("SSL certificates generated successfully!")
      :ok
    else
      {:error, reason} ->
        Mix.shell().error("Failed to setup SSL certificates: #{reason}")
        exit({:shutdown, 1})
    end
  end

  defp check_mkcert_installed do
    case System.find_executable("mkcert") do
      nil ->
        {:error, "mkcert not found. Please install it from https://github.com/FiloSottile/mkcert"}

      _path ->
        :ok
    end
  end

  defp generate_certificates do
    cert_path = Path.join(@cert_dir, @cert_file)
    key_path = Path.join(@cert_dir, @key_file)

    if certificates_exist?(cert_path, key_path) do
      Mix.shell().info("Certificates already exist, skipping generation.")
      :ok
    else
      generate_new_certificates(cert_path, key_path)
    end
  end

  defp certificates_exist?(cert_path, key_path) do
    File.exists?(cert_path) and File.exists?(key_path)
  end

  defp generate_new_certificates(cert_path, key_path) do
    Mix.shell().info("Generating certificates for: #{Enum.join(@hosts, ", ")}")

    args = ["-cert-file", cert_path, "-key-file", key_path | @hosts]

    case System.cmd("mkcert", args, stderr_to_stdout: true) do
      {output, 0} ->
        Mix.shell().info(output)
        :ok

      {output, exit_code} ->
        {:error, "mkcert command failed with exit code #{exit_code}: #{output}"}
    end
  end

  defp copy_to_android do
    source = Path.join(@cert_dir, @cert_file)
    dest_dir = @android_cert_dir
    dest = Path.join(dest_dir, @cert_file)

    with :ok <- verify_android_project_exists(dest_dir),
         :ok <- ensure_directory(dest_dir),
         :ok <- copy_certificate_file(source, dest) do
      :ok
    end
  end

  defp verify_android_project_exists(android_cert_dir) do
    android_root = Path.join([android_cert_dir, "..", "..", "..", ".."])
    gradle_file = Path.join(android_root, "build.gradle.kts")

    if File.exists?(gradle_file) do
      :ok
    else
      Mix.shell().error(
        "Android project not found (monorepo structure may vary), skipping certificate copy."
      )

      :ok
    end
  end

  defp ensure_directory(dir) do
    case File.mkdir_p(dir) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, "Failed to create directory #{dir}: #{inspect(reason)}"}
    end
  end

  defp copy_certificate_file(source, dest) do
    case File.cp(source, dest) do
      :ok ->
        Mix.shell().info("Copied certificate to #{dest}")
        :ok

      {:error, reason} ->
        {:error, "Failed to copy certificate to Android project: #{inspect(reason)}"}
    end
  end
end
