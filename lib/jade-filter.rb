module Haml::Filters::Jade
  include Haml::Filters::Base

  def render(text, options)
    <<END
<script type="text/tempate" id=#{options[:id]}> 
#{text}
</script>
END
  end
end
