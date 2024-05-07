<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\HttpFoundation\Response;

class YearController extends AbstractController
{
    #[Route('/year', name: 'app_year')]
    public function getRandomYear(): Response
    {
        $currentYear = date("Y"); // Get the current year
        usleep(rand(0, 5000)); // Simulate a small delay
        $randomYear = rand(2015, $currentYear); // Get a random year between 2015 and current year

        return new Response((string) $randomYear, 200, ['Content-Type' => 'text/plain']);
    }

}
