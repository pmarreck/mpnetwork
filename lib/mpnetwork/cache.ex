defmodule Mpnetwork.Cache do
  alias Mpnetwork.Schema.Cache
  alias Mpnetwork.{Repo, Config}
  import Ecto.Query

  defp fn_arity(fun), do: :erlang.fun_info(fun)[:arity]

  # private API to DB

  defp create_cache(%{} = attrs) do
    %Cache{}
    |> Cache.changeset(attrs)
    |> Repo.insert()
  end

  # defp read_cache!(key), do: get_cache!(key)
  defp get_cache!(key), do: Repo.get_by!(Cache, key: key)

  # defp read_cache(key), do: get_cache(key)
  defp get_cache(key), do: Repo.get_by(Cache, key: key)

  defp update_cache(%Cache{} = cache, attrs \\ %{}) do
    cache
    |> Cache.changeset(attrs)
    # forces timestamps to update
    |> Repo.update(force: true)
  end

  defp delete_cache(%Cache{} = cache) do
    Repo.delete(cache)
  end

  # defp change_cache(%Cache{} = cache) do
  #   Cache.changeset(cache, %{})
  # end

  defp hash(nil), do: nil
  defp hash(val) when is_binary(val), do: :crypto.hash(:sha256, val)
  defp hash(_), do: nil

  # public API

  def get(key), do: get(Config.get(:cache_name), key, [])
  def get(cache_name, key), do: get(cache_name, key, [])

  def get(cache_name, key, _opts) do
    case get_cache({cache_name, key}) do
      %Cache{value: value} -> value
      anything_else -> anything_else
    end
  end

  def get!(key), do: get!(Config.get(:cache_name), key, [])
  def get!(cache_name, key), do: get!(cache_name, key, [])

  def get!(cache_name, key, _opts) do
    %Cache{value: value} = get_cache!({cache_name, key})
    value
  end

  def fetch(key, fallback), do: fetch(Config.get(:cache_name), key, fallback, [])
  def fetch(key, fallback, opts), do: fetch(Config.get(:cache_name), key, fallback, opts)

  def fetch(cache_name, key, fallback, _opts) when is_function(fallback) do
    fallback =
      case fn_arity(fallback) do
        0 -> fn -> fallback.() end
        1 -> fn -> fallback.(key) end
      end

    case get_cache({cache_name, key}) do
      %Cache{value: value} ->
        {:ok, value}

      _ ->
        fallback_val = fallback.()

        {:ok, %Cache{value: value}} =
          create_cache(%{
            key: {cache_name, key},
            value: fallback_val,
            sha256_hash: hash(fallback_val)
          })

        {:loaded, value}
    end
  end

  def fetch(cache_name, key, nil, opts) do
    {:ok, get(cache_name, key, opts)}
  end

  def put(key, value), do: put(Config.get(:cache_name), key, value, [])
  def put(cache_name, key, value), do: put(cache_name, key, value, [])

  def put(cache_name, key, value, _opts) when is_binary(value) or is_nil(value) do
    case get_cache({cache_name, key}) do
      %Cache{} = cache -> update_cache(cache, %{value: value, sha256_hash: hash(value)})
      _ -> create_cache(%{key: {cache_name, key}, value: value, sha256_hash: hash(value)})
    end
  end

  # def put!(cache_name, key, value, opts) when is_binary(value) do

  def set(key, value), do: set(Config.get(:cache_name), key, value, [])
  def set(cache_name, key, value), do: set(cache_name, key, value, [])
  def set(cache_name, key, value, opts), do: put(cache_name, key, value, opts)

  # def set!(key, value), do: set!(Config.get(:cache_name), key, value, [])
  # def set!(cache_name, key, value), do: set!(cache_name, key, value, [])
  # def set!(cache_name, key, value, opts), do: put!(cache_name, key, value, opts)

  def del(key), do: del(Config.get(:cache_name), key, [])
  def del(cache_name, key), do: del(cache_name, key, [])

  def del(cache_name, key, _opts) do
    case get_cache({cache_name, key}) do
      %Cache{} = cache -> delete_cache(cache)
      anything_else -> anything_else
    end
  end

  def touch(key), do: touch(Config.get(:cache_name), key, [])
  def touch(cache_name, key), do: touch(cache_name, key, [])

  def touch(cache_name, key, _opts) do
    case get_cache({cache_name, key}) do
      # a no-op that just updates the timestamp
      %Cache{} = cache -> update_cache(cache)
      _ -> create_cache(%{key: {cache_name, key}, value: nil, sha256_hash: nil})
    end
  end

  # expire all cache entries that haven't been accessed in a month
  # Currently applies to all caches regardless of name
  def purge(), do: purge(Config.get(:cache_name))
  def purge(cache_name), do: purge(cache_name, Config.get(:default_cache_expiry))

  def purge(_cache_name, :now) do
    from(c in Cache, select: c.id) |> Repo.delete_all()
  end

  def purge(_cache_name, opts) do
    ago = NaiveDateTime.utc_now() |> Timex.shift(opts)
    # select all keys whose updated_at is older than the configured duration
    from(
      c in Cache,
      where: c.updated_at < ^ago,
      select: c.id
    )
    |> Repo.delete_all()
  end

  def purge_default_cache_now() do
    purge(Config.get(:cache_name), :now)
  end

  # def dump(cache_name, path, opts \\ [])

  # def clear(cache_name) do

  # end

  # def load(cache_name, path, opts \\ [])

  def count(), do: count(Config.get(:cache_name), [])
  def count(cache_name, opts \\ []), do: size(cache_name, opts)

  def size(), do: size(Config.get(:cache_name), [])

  def size(cache_name, _opts \\ []) do
    keys(cache_name) |> Enum.count()
  end

  # def incr(cache_name, key, amount \\ 1, opts \\ [])

  # def decr(cache_name, key, amount \\ 1, opts \\ []), do: incr(cache_name, key, amount * -1, opts)

  def keys(), do: keys(Config.get(:cache_name), [])

  def keys(cache_name, _opts \\ []) do
    Repo.all(from(c in "cache", select: c.key))
    |> Enum.map(fn binary -> :erlang.binary_to_term(binary) end)
    |> Enum.filter(fn {cn, _key} -> cn == cache_name end)
    |> Enum.map(fn {_cn, key} -> key end)
  end
end
