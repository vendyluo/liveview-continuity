defmodule LiveViewContinuity.RadioGroupTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  defp render_group(value), do: render_group(value, [], nil)
  defp render_group(value, attrs), do: render_group(value, attrs, nil)

  defp render_group(value, attrs, options) do
    options = options || [option("email", "Email"), option("phone", "Phone", disabled: true)]

    render_component(
      &LiveViewContinuity.RadioGroup.radio_group/1,
      Keyword.merge(
        [
          id: "contact",
          name: "contact_method",
          value: value,
          on_change: "change",
          label: "Contact method",
          option: options
        ],
        attrs
      )
    )
  end

  test "renders native semantics and complete ARIA graph" do
    html =
      render_group("email",
        required: true,
        invalid: true,
        description: [slot("Help")],
        error: [slot("Choose one")]
      )

    assert html =~ ~s(<fieldset id="contact" role="radiogroup")
    assert html =~ ~s(aria-labelledby="contact-legend")
    assert html =~ ~s(aria-describedby="contact-description contact-error")
    assert html =~ ~s(aria-required="true")
    assert html =~ ~s(aria-invalid="true")
    assert html =~ ~s(<legend id="contact-legend" class="">Contact method</legend>)
    assert html =~ ~s(id="contact-option-email" type="radio" name="contact_method" value="email")
    assert html =~ ~s(for="contact-option-email" class="">Email</label>)
    assert input_tag(html, "contact-option-email") =~ ~r/\schecked(?:\s|>)/
    assert input_tag(html, "contact-option-email") =~ ~r/\srequired(?:\s|>)/
    refute input_tag(html, "contact-option-phone") =~ ~r/\schecked(?:\s|>)/
    refute html =~ ~s(role="radio")
  end

  test "renders nil and selected state, disabled/read-only and consumer attributes" do
    nil_html = render_group(nil)
    refute nil_html =~ ~s( checked)
    assert nil_html =~ ~s(data-lvc-desired-has-value="false")

    html =
      render_group("phone",
        disabled: true,
        read_only: true,
        form: "other",
        class: "root",
        legend_class: "legend",
        rest: %{"data-test": "yes"}
      )

    assert html =~ ~s(class="root")
    assert html =~ ~s(class="legend")
    assert html =~ ~s(form="other")
    assert html =~ ~s(aria-disabled="true")
    assert html =~ ~s(aria-readonly="true")
    assert html =~ ~s(data-test="yes")
    assert html =~ ~s(id="contact-option-phone")
    assert opening_tag(html, "fieldset", "contact") =~ ~r/\sdisabled(?:\s|>)/
    assert input_tag(html, "contact-option-email") =~ ~r/\sdisabled(?:\s|>)/
  end

  test "description is always referenced and error only while invalid" do
    html = render_group("email", description: [slot("Help")], error: [slot("Error")])
    assert html =~ ~s(aria-describedby="contact-description")
    assert html =~ ~s(id="contact-error" class="" hidden)
    refute html =~ ~s(aria-describedby="contact-description contact-error")
  end

  test "rejects invalid composition" do
    for {attrs, options, message} <- [
          {[id: "bad id"], nil, "radio group id"},
          {[name: "  "], nil, "name"},
          {[name: "bad\0name"], nil, "name"},
          {[label: "\n"], nil, "label"},
          {[], [], "at least one"},
          {[], [option("bad id", "Bad")], "option value"},
          {[], [option("x", "X"), option("x", "Again")], "unique"},
          {[], [option("x", " ")], "option label"},
          {[value: "missing"], [option("x", "X")], "existing option"},
          {[description: [slot("a"), slot("b")]], nil, "at most one description"},
          {[error: [slot("a"), slot("b")]], nil, "at most one error"}
        ] do
      assert_raise ArgumentError, ~r/#{message}/, fn -> render_group("email", attrs, options) end
    end
  end

  defp option(value, label, attrs \\ []),
    do: Map.merge(%{value: value, label: label}, Map.new(attrs))

  defp slot(text), do: %{inner_block: fn _, _ -> text end}
  defp input_tag(html, id), do: opening_tag(html, "input", id)

  defp opening_tag(html, tag, id) do
    [match] = Regex.run(~r/<#{tag}(?=[^>]*\sid="#{Regex.escape(id)}")[^>]*>/, html)
    match
  end
end
