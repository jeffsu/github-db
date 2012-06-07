class Integer
  def days
    sec = min = 60
    day =  24
    return( self * ( day * (sec * min)))
  end

  def years
    year = 365
    return( year * self.days)
  end

  def ago
    return( Time.now - self)
  end

end
