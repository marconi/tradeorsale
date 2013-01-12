<%def name="render_field(field, **kwargs)">
<div class="control-group field-${field.id} ${'error' if field.errors else ''}">
  % if not 'is_checkbox' in kwargs:
    ${field.label(**{'class': 'control-label'})}
  % endif

  <div class="controls">
  % if 'prepend' in kwargs:
    <div class="input-prepend">
      <span class="add-on">${_(kwargs.pop('prepend'))}</span>
      ${field(**kwargs)|h}
    </div>
  % elif 'is_checkbox' in kwargs:
      <label class="checkbox control-label" for="${field.id}">
        ${field(**kwargs)|h} ${field.label.text}
      </label>
  % else:
    ${field(**kwargs)|h}
  % endif
  
  % if field.description:
    <span class="help-inline field-description">${field.description}</span>
  % endif

  % if field.errors:
    % for error in field.errors:
      <span class="help-inline">${error}</span>
    % endfor
  % endif
  </div>
</div>
</%def>