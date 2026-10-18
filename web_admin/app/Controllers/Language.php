<?php

namespace App\Controllers;

class Language extends BaseController
{
    /**
     * Switch application language between English ('en') and Indonesian ('id').
     * Defaults to English ('en').
     */
    public function switch(string $locale = 'en')
    {
        $locale = strtolower(trim($locale));
        if (in_array($locale, ['en', 'id'], true)) {
            session()->set('locale', $locale);
            service('language')->setLocale($locale);
            $this->request->setLocale($locale);
        }

        // Check for redirect target
        $returnUrl = $this->request->getGet('return_url');
        if (!empty($returnUrl) && filter_var($returnUrl, FILTER_VALIDATE_URL)) {
            return redirect()->to($returnUrl);
        }

        $prev = previous_url();
        if (!empty($prev) && $prev !== current_url()) {
            return redirect()->to($prev);
        }

        return redirect()->to(site_url('dashboard'));
    }
}
