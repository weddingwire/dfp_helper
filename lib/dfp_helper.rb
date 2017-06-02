module DfpHelper
  class Railtie < Rails::Railtie
    initializer "dfp_helper.view_helpers" do
      ActionView::Base.send :include, ViewHelpers
    end
  end

  module ViewHelpers
    def dfp_helper_slots
      @dfp_helper_slots||=[]
    end
    def dfp_helper_slot(_i, options = {})
      @@dfp_helper_id ||= (Time.now.to_f*1000).to_i
      options[:hide_empty] ||= false
      _id = options[:div_id]
      _id ||= "div-gpt-ad-#{@@dfp_helper_id}-#{dfp_helper_slots.size}"
      _size = options[:size] || _i.match(/\d+x\d+/)[0].split('x')
      _styles = options[:responsive_mapping] ? '' : "width:#{_size[0]}px; height:#{_size[1]}px;"
      dfp_helper_slots << options.merge({:id => _i, :div_id => _id, :size => _size})

      raw <<-END.strip
<!-- #{_i} -->
<div id='#{_id}' style=#{_styles} class='#{options[:div_class]}'>
<script type='text/javascript'>
googletag.cmd.push(function() {
  if(#{options[:hide_empty]}) {
      window.gtag_ad_slots['#{_i}'].setCollapseEmptyDiv(true);
  }
  googletag.display('#{_id}');
});
</script>
</div>
      END
    end

    def dfp_define_slot(_i, options = {})
      @@dfp_helper_id ||= (Time.now.to_f*1000).to_i
      _id = options[:div_id]
      _id ||= "div-gpt-ad-#{@@dfp_helper_id}-#{dfp_helper_slots.size}"
      _size = options[:size] || _i.match(/\d+x\d+/)[0].split('x')
      dfp_helper_slots << options.merge({:id => _i, :div_id => _id, :size => _size})

      raw <<-END.strip
<script type='text/javascript'>
var #{options[:slot_name]};
</script>
      END
    end

    def dfp_helper_head(options={single_request:true})
      return unless dfp_helper_slots.size > 0
      o = dfp_helper_slots.collect{|i|
        _targeting = (i[:targeting]||[]).collect{|k,v| ".setTargeting(#{k.to_json}, #{v.to_json})"}.join
        _slot_name = (i[:slot_name].blank?)?"":"#{i[:slot_name]} = "
        "window.gtag_ad_slots['#{i[:id]}'] = #{_slot_name}googletag.defineSlot('#{i[:id]}', [#{i[:size].map(&:to_s).join(', ')}], '#{i[:div_id]}').defineSizeMapping(#{i[:responsive_mapping]}).addService(googletag.pubads())#{_targeting};"
      }.join("\n")
      sra = "googletag.pubads().enableSingleRequest();" if options[:single_request]
      raw <<-END.strip
<script type='text/javascript'>
var googletag = googletag || {};
var gtag_ad_slots = gtag_ad_slots || {};
googletag.cmd = googletag.cmd || [];
(function() {
var gads = document.createElement('script');
gads.async = true;
gads.type = 'text/javascript';
var useSSL = 'https:' == document.location.protocol;
gads.src = (useSSL ? 'https:' : 'http:') +
'//www.googletagservices.com/tag/js/gpt.js';
var node = document.getElementsByTagName('script')[0];
node.parentNode.insertBefore(gads, node);
})();
</script>

<script type='text/javascript'>
googletag.cmd.push(function() {
#{o}
#{sra}
googletag.enableServices();
});
</script>
      END
    end

    def dfp_helper_head_mobile
      raw <<-END.strip
<script type='text/javascript'>
(function() {
var useSSL = 'https:' == document.location.protocol;
var src = (useSSL ? 'https:' : 'http:') +
'//www.googletagservices.com/tag/js/gpt_mobile.js';
document.write('<scr' + 'ipt src="' + src + '"></scr' + 'ipt>');
})();
</script>
      END
    end

    def dfp_helper_mobile_tag(_i, options = {})
      @@dfp_helper_id ||= (Time.now.to_f*1000).to_i
      _id = options[:div_id]
      _id ||= "div-gpt-ad-#{@@dfp_helper_id}-#{dfp_helper_slots.size}"
      _size = options[:size] || _i.match(/\d+x\d+/)[0].split('x')
      options.merge!({:id => _i, :div_id => _id, :size => _size})
      options[:hide_empty] ||= false

      raw <<-END.strip
<div id='#{_id}' class='mobile-ad #{options[:div_class]}'>
<script type='text/javascript'>
googletag.cmd.push(function() {
var slot = googletag.defineSlot('#{_i}', #{options[:size]}, '#{options[:div_id]}')
.addService(googletag.pubads());
if(#{options[:hide_empty]}) {
  slot.setCollapseEmptyDiv(true);
}
googletag.enableServices();
googletag.display('#{options[:div_id]}');
});
</script>
</div>
END
    end

    #
    # browser_mapping's first param is expecting an array of [w,h] for browser
    # to map responsive ad size to
    #
    # browser_mapping is expecting 0+ arrays of [w,h] for ad sizes
    # which will be permitted for that browser size
    #
    # browser_and_ad_sizes is expecting an array of arrays
    # ex) *browser_mapping ==> [[1024, 768], [970, 250]][[1024, 768], [970, 250]]
    #
    # first array is browser size and every subsequent array is an ad size [w,h]
    #
    # Assign responsive_gpt_mapping to a variable to pass to
    # map_responsive_add_sizes()
    #

    def responsive_gpt_mapping(*browser_mapping)
      total_mapping = ''
      browser_mapping.each do |mapping|
        total_mapping += ".addSize(#{mapping.first},#{mapping[1..-1].map(&:to_s).join(',')})"
      end

      "googletag.sizeMapping()#{total_mapping}.build()"
    end
  end
end
