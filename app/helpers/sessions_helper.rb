module SessionsHelper
  def log_in(user)
    session[:user_id] = user.id
  end
  
  def remember(user)
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = Digest::MD5.hexdigest(user.private_token)
  end
  
  def redirect_back_or(default)
    redirect_to(session[:forward_to] || default)
    session.delete(:forward_to)
  end
  
  def store_location
    session[:forward_to] = request.url if request.get?
  end
  
  def current_user
    
    # if Rails.env.development?
    #   @current_user ||= User.find_by(id: 1)
    #   return @current_user
    # end
    
    if session[:user_id]
      @current_user ||= User.find_by(id: session[:user_id])
    elsif cookies.signed[:user_id]
      user = User.find_by(id: cookies.signed[:user_id])
      if user && Digest::MD5.hexdigest(user.private_token) == cookies[:remember_token]
        log_in user
        @current_user = user
      end
    end
  end
  
  def log_out
    cookies.delete :user_id
    cookies.delete :remember_token
    session.delete(:user_id)
    @current_user = nil
  end
end