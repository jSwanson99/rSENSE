$ ->

  hide_upload = ->
    if ($ '#collapsefields div table tbody tr').size() == 1
      ($ '#collapsecreate_data_set').hide()
    else
      ($ '#collapsecreate_data_set').show()

      
  hide_upload();  
  
  #This is where we edit 
  edit = ->
    name = ($ @).parent().parent().find '.field_name'
    unit = ($ @).parent().parent().find '.field_unit'
    field = helpers.get_field_type $(@).parent().parent().find('.field_type').text()

    if not (field in [(helpers.get_field_type "Latitude"), (helpers.get_field_type "Longitude")])
      name.wrapInner "<input type='text' class='name_edit_box' value='#{name.text().trim()}'>"
      unit.wrapInner "<input type='text' class='unit_edit_box' value='#{unit.text().trim()}'>" if field is (helpers.get_field_type "Number")
      name.find('.name_edit_box').focus()

    ($ @).hide()
    ($ @).siblings('.field_save_link').show()
    
    $.ajax
      url: ($ @).siblings('.field_delete_link').attr 'href'
      type: "GET"
      dataType: "json"
      success: (msg) =>
        if msg.ses.length is 0
          ($ @).siblings('.field_delete_link').show()


  #This is where we save after editing    
  save = (e) ->
  
    e.preventDefault()
    name = ($ @).parent().parent().find '.field_name'
    unit = ($ @).parent().parent().find '.field_unit'
    field = helpers.get_field_type ($(@).parent().parent().find('.field_type').text())

    if not (field in [(helpers.get_field_type "Latitude"), (helpers.get_field_type "Longitude")])
      name_text = name.find('.name_edit_box').val().trim()
      unit_text = if field is (helpers.get_field_type "Number")
        unit.find('.unit_edit_box').val().trim()
      else
        ""

      data={}
      data['field'] = {}
      data['field']['name'] = name_text
      data['field']['unit'] = unit_text
      exp_id = ($ @).attr('exp')
      field_id = ($ @).attr('field')
      url = '/projects/' + exp_id + '/' + field_id + '/checkFieldName'
      
      
    	#check that no field has this name already
      $.ajax
        url: url
        dataType: "json"
        data: data
        success: (msg, xhtm, options) =>
          if msg.orig == true
            ($ name).find('.name_edit_box').css('background-color', '#FFFFFF')
            #if nothing does save it with this new name
            $.ajax
              url: $(@).attr('href')
              type: "PUT"
              dataType: "json"
              data: data
              success: =>
                ($ @).siblings('.field_edit_link').show()
                ($ @).hide()
                ($ @).siblings('.field_delete_link').hide()
                name.html(name_text)
                unit.html(unit_text)
          else
            ($ name).find('.name_edit_box').css('background-color', '#D80000')

      hide_upload();  

            
    else
      ($ @).siblings('.field_edit_link').show()
      ($ @).hide()
      ($ @).siblings('.field_delete_link').hide()  
          
    false

  remove_field = ->
  
    row = ($ @).parent().parent()
    type = helpers.get_field_type ($ row).find('.field_type').text()
    
    pair_field = null
    
    if( ($ row).siblings().length <= 1 )
        ($ '#create_data_set').hide()

    if not (type in [(helpers.get_field_type "Latitude"), (helpers.get_field_type "Longitude")])  
      $.ajax
        url: ($ @).attr('href') + "/removeField"
        type: "POST"
        dataType: "json"
        data: {field_id: ($ @).attr 'field'}
        success: (msg) =>
          ($ @).parent().parent().remove()
        error: (msg) =>
          console.log msg
    else
      if confirm "Latitude and Longitude must be deleted together\nAre you sure you would like to continue?"
        sibs = $ row.siblings()
        
        for sib in sibs
          do (sib) ->
            sib_type = ($ sib).find('td[class="field_type"]').text()
            if((sib_type is "Longitude") or (sib_type is "Latitude"))
              pair_field = sib
        
        $.ajax
          url: ($ row).find('.field_delete_link').attr('href') + "/removeField"
          type: "POST"
          dataType: "json"
          data: {field_id: ($ row).find('.field_delete_link').attr 'field'}
          success: (msg) =>
            ($ row).remove()
            ($ '#add-field-dropdown ul li a.add_location_field').show()
          error: (msg) =>
            console.log msg
            
            
        $.ajax
          url: ($ pair_field).find('.field_delete_link').attr('href') + "/removeField"
          type: "POST"
          dataType: "json"
          data: {field_id: ($ pair_field).find('.field_delete_link').attr 'field'}
          success: (msg) =>
            ($ pair_field).remove()
          error: (msg) =>
            console.log msg
            
    hide_upload();  
    
    false

  addField = (type) ->
  
    typeName = helpers.get_field_name type
    unit = helpers.get_default_unit type
    
    $.ajax
      url: '/fields/'
      type: 'POST'
      dataType: 'json'
      data:
        field:
          project_id: ($ '.fields_table').attr 'project'
          name: typeName
          unit: unit
          field_type: type
      success: (msg) =>
        htmlStr  = "<tr>"
        htmlStr += "<td class='field_name'>#{msg.name}</td>"
        htmlStr += "<td class='field_unit'>#{unit}</td>"
        htmlStr += "<td class='field_type'>#{typeName}</td>"
        ($ '#create_data_set').show()
        
        #if not (type in [(helpers.get_field_type "Latitude"), (helpers.get_field_type "Longitude")])
        htmlStr += "<td class='token'><a class='field_edit_link'><i class='icon-edit'></i></a>"
        htmlStr += "<a href='/fields/#{msg.id}' exp='#{msg.project_id}' field='#{msg.id}' class='field_save_link'><i class='icon-ok'></i></a>"
        htmlStr += "<a href='" + window.location.pathname  + "' field='#{msg.id}' class='field_delete_link'><i class='icon-remove-circle'></i></a></td>"
        #else
          #htmlStr += "<td></td>"
        
        htmlStr += "</tr>"
        ($ '.fields_table').append htmlStr


        ($ '.token').find('.field_edit_link').click edit
        ($ '.token').find('.field_save_link').click save
        ($ '.token').find('.field_delete_link').click remove_field
        ($ '.token').removeClass 'token'

        if not (type in [(helpers.get_field_type "Latitude"), (helpers.get_field_type "Longitude")])
          ($ '.field_edit_link').last().trigger 'click'

    hide_upload();  
          
  ($ '.field_edit_link').click edit
  ($ '.field_save_link').click save
  ($ '.field_delete_link').click remove_field

  ($ '.add_timestamp_field').click ->
    addField helpers.get_field_type 'Timestamp'

  ($ '.add_number_field').click ->
    addField helpers.get_field_type 'Number'

  ($ '.add_text_field').click ->
    addField helpers.get_field_type 'Text'

  ($ '.add_location_field').click ->
    addField helpers.get_field_type 'Latitude'
    addField helpers.get_field_type 'Longitude'
    ($ '#add-field-dropdown ul li a.add_location_field').hide()

    
  