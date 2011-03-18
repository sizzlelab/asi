var jsontest = (function() {
    return {
        INDENT: 2,

        template: null,
        _loading: false,

        init: function() {
            jsontest.template = $('#responses .template').clone().removeClass('template');
            $('#responses ol').empty();

            $('#execButton').click(jsontest.exec);
            $('#console').submit(function() {
                jsontest.exec();
                return false;
            })

            $('#url').focus();
        },
        loading: {
            start: function() {
                if (jsontest._loading) {
                    return;
                }
                jsontest._loading = true;
                $('#responses ol').append('<li class="loading response"><img src="/images/loading.gif" alt="loading..."/></li>');
            },
            stop: function() {
                $('#responses ol .loading').remove();
                jsontest._loading = false;
            }
        },
        exec: function() {
            var at = $('#authenticityToken').val();
            var method = $('#method').val();
            var url = $('#url').val();
            var params = $('#params').val();
            var pretty = $('#pretty:checked').val();

            jsontest.loading.start();

            if (url == '') {
                alert('Please enter a url');
                $('#url').focus();
                return false;
            }

            $.ajax({
                type: method,
                url: url,
                data: params,
                dataType: 'json',
                complete: function(jqXHR, textStatus) {
                    var spec = {
                        method: method,
                        url: url,
                        params: params,
                        status: jqXHR.status,
                        pretty: pretty
                    }
                    if (jqXHR.status == 500) {
                        spec.responseText = 'Internal error';
                    }
                    else {
                        spec.responseText = jqXHR.responseText;
                    }
                    jsontest.loading.stop();
                    jsontest.render(spec);
                }
            })
        },
        render: function(spec) {
            r = jsontest.template.clone();
            r.find('.method').text(spec.method);
            r.find('.url').text(spec.url);
            r.find('.status').text(spec.status);
            
            // pretty spacing
            if (spec.pretty) {
                spec.responseText = jsontest.makePrettySpacing(spec.responseText);
            }
            r.find('.responseText').text(spec.responseText);

            // add the result to the page
            $('#responses ol').append(r);

            // colour
            if (spec.pretty) {
                r.find('.responseText').addClass('prettyprint');
                prettyPrint();
            }
        },
        makePrettySpacing: function(s) {
            try {
                return JSON.stringify(JSON.parse(s), null, jsontest.INDENT);
            }
            catch(ex) {
                return s;
            }
        }
    }
})();


/* on dom ready */
$(function() {
    jsontest.init();
})

