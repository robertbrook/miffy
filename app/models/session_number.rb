class SessionNumber
  
  PARLIAMENT_YEARS = {
54 => 2005,
53 => 2001,
52 => 1997,
51 => 1992,
50 => 1987,
49 => 1983,
48 => 1979
}
  
  class << self    
    def convert_to_session(session_number)
      session = session_number.split('/')
      parl_start_year = PARLIAMENT_YEARS[session[0].to_i]
      current_year = parl_start_year + (session[1].to_i - 1)
      following_year = (current_year + 1).to_s[2..4]
      current_year.to_s << "-" << following_year
    end
  end
  
end