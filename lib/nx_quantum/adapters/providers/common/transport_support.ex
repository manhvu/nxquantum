defmodule NxQuantum.Adapters.Providers.Common.TransportSupport do
  @moduledoc false

  @live_smoke_env "NXQ_PROVIDER_LIVE_SMOKE"
  @live_env "NXQ_PROVIDER_LIVE"

  @spec readiness(atom() | String.t(), keyword(), [atom()], atom()) :: map()
  def readiness(provider, opts, required_config_keys, operation) when is_list(opts) and is_list(required_config_keys) do
    provider_config = Keyword.get(opts, :provider_config, %{})
    requested_mode = requested_mode(opts, provider_config)
    live_smoke_enabled = env_enabled?(provider, @live_smoke_env)
    live_enabled = env_enabled?(provider, @live_env)
    missing_config_keys = Enum.reject(required_config_keys, &Map.has_key?(provider_config, &1))
    live_smoke_ready? = requested_mode == :live_smoke and live_smoke_enabled and missing_config_keys == []
    live_ready? = requested_mode == :live and live_enabled and missing_config_keys == []
    resolved_mode = resolved_mode(requested_mode, live_smoke_ready?, live_ready?)

    %{
      provider: provider,
      operation: operation,
      requested_mode: requested_mode,
      mode: resolved_mode,
      fixture_first?: resolved_mode == :fixture,
      downgraded_to_fixture?: requested_mode in [:live_smoke, :live] and resolved_mode == :fixture,
      live: %{
        requested?: requested_mode == :live,
        env_enabled?: live_enabled,
        ready?: live_ready?,
        env_key: env_key(provider, @live_env),
        missing_config_keys: missing_config_keys,
        required_config_keys: required_config_keys
      },
      live_smoke: %{
        requested?: requested_mode == :live_smoke,
        env_enabled?: live_smoke_enabled,
        ready?: live_smoke_ready?,
        env_key: env_key(provider, @live_smoke_env),
        missing_config_keys: missing_config_keys,
        required_config_keys: required_config_keys
      }
    }
  end

  @spec requested_mode(keyword(), map()) :: :fixture | :live_smoke | :live
  def requested_mode(opts, provider_config) when is_list(opts) and is_map(provider_config) do
    Enum.find(
      [
        Keyword.get(opts, :transport_mode),
        transport_flag(opts, :live, :live),
        transport_flag(opts, :live_smoke, :live_smoke),
        Map.get(provider_config, :transport_mode),
        transport_flag(provider_config, :live, :live),
        transport_flag(provider_config, :live_smoke, :live_smoke)
      ],
      :fixture,
      &(&1 in [:live, :live_smoke])
    )
  end

  @spec env_enabled?(atom() | String.t(), String.t()) :: boolean()
  def env_enabled?(provider, prefix) do
    env_key = env_key(provider, prefix)

    case {parse_env(System.get_env(prefix)), parse_env(System.get_env(env_key))} do
      {true, _} -> true
      {_, true} -> true
      _ -> false
    end
  end

  @spec env_key(atom() | String.t(), String.t()) :: String.t()
  def env_key(provider, prefix), do: "#{prefix}_#{provider_name(provider)}"

  @spec require_live_ready(map(), atom()) :: :ok | {:error, {:provider_capability_mismatch, atom()}}
  def require_live_ready(%{requested_mode: :live, mode: :fixture}, _operation),
    do: {:error, {:provider_capability_mismatch, :live_mode_unavailable}}

  def require_live_ready(_readiness, _operation), do: :ok

  defp resolved_mode(:live, _live_smoke_ready?, live_ready?) when live_ready?, do: :live
  defp resolved_mode(:live_smoke, live_smoke_ready?, _live_ready?) when live_smoke_ready?, do: :live_smoke
  defp resolved_mode(_requested_mode, _live_smoke_ready?, _live_ready?), do: :fixture

  defp provider_name(provider) when is_atom(provider), do: provider |> Atom.to_string() |> String.upcase()
  defp provider_name(provider) when is_binary(provider), do: String.upcase(provider)

  defp transport_flag(container, key, mode) when is_list(container), do: if(Keyword.get(container, key, false), do: mode)
  defp transport_flag(container, key, mode) when is_map(container), do: if(Map.get(container, key, false), do: mode)

  defp parse_env(nil), do: false
  defp parse_env("1"), do: true
  defp parse_env("true"), do: true
  defp parse_env("0"), do: false
  defp parse_env("false"), do: false
  defp parse_env(_other), do: false
end
