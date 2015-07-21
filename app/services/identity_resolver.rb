class IdentityResolver
  attr_reader :sign_in_user, :flash

  def initialize current_user, auth
    @auth = auth

    if session_provider?
      if current_user
        @flash = "Already signed in!"
      else
        @sign_in_user = upsert_user
        @flash = 'Signed in!'
      end
    else
      if (provider = find_provider)
        #It's a known provider
        if current_user
          if current_user != provider.user
            @flash = "User #{uid} belongs to another user."
          else
            @flash = "Provider already connected."
          end
        else
          @sign_in_user = provider.user
          @flash = 'Signed in!'
        end
      else
        # First time we encounter this provider
        unless current_user
          # We must have a sign in user to create the provider
          @flash = "Please sign in first."
        else
          create_provider_for current_user
          @flash = "Connected successfully."
        end
      end
    end
  end

  private

  def provider_name
    @auth.fetch 'provider'
  end

  def uid
    @auth.fetch 'uid'
  end

  def beeminder_token
    @auth.fetch('credentials').fetch('token')
  end

  def find_provider
    Provider.find_by(
      name: provider_name,
      uid: uid
    )
  end

  def session_provider?
    'beeminder' == provider_name
  end

  def create_provider_for user
    params = @auth.slice('uid', 'info', 'credentials', 'extra').to_h
    provider = Provider.new params.merge(user: user)
    provider.name = provider_name
    provider.save!
  end

  def upsert_user
    User.upsert uid, beeminder_token
  end
end